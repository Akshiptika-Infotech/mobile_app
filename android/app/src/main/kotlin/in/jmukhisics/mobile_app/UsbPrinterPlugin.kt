package `in`.jmukhisics.mobile_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class UsbPrinterPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var usbManager: UsbManager? = null

    companion object {
        const val CHANNEL = "usb_thermal_printer"
        const val ACTION_USB_PERMISSION = "in.jmukhisics.mobile_app.USB_PERMISSION"

        // Known thermal printer vendor IDs (VID as decimal)
        val PRINTER_VIDS = setOf(
            0x0483, // STMicroelectronics – common cheap thermal / Helett printers
            0x28e9, // GreenFan / GOOJPRT / Helett variants
            0x0416, // WinChipHead / CH34x
            0x067b, // Prolific PL2303
            0x04b8, // Epson
            0x0519, // Woosim / Bixolon
            0x0fe6, // IDS / Datecs
            0x2730, // various cheap brands
            0x0dd4, // Custom Works
            0x1504, // Hoinprinter
            0x154f, // SEIKO
            0x0ced, // SimplyWorks
            0x2080, // Helett / common label printers
            0x6868, // Helett thermal
            0x0525, // Netchip / generic USB
            0x1a86, // QinHeng CH34x (common in cheap printers)
            0x10c4, // Silicon Labs CP210x
            0x0557, // ATEN USB
            0x353D, // Helett H30C Lite (confirmed VID from diagnose)
        )
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as? UsbManager
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "listPrinters"       -> listPrinters(result)
            "isPrinterConnected" -> result.success(findPrinterDevice() != null)
            "requestPermission"  -> {
                val name = call.argument<String>("deviceName")
                    ?: return result.error("INVALID", "deviceName required", null)
                requestPermission(name, result)
            }
            "printBytes"         -> {
                val name = call.argument<String>("deviceName")
                    ?: return result.error("INVALID", "deviceName required", null)
                val data = call.argument<ByteArray>("data")
                    ?: return result.error("INVALID", "data required", null)
                // Run on background thread to avoid ANR
                Thread {
                    printBytes(name, data, result)
                }.start()
            }
            "diagnose"           -> diagnose(result)
            else -> result.notImplemented()
        }
    }

    // ── Device discovery ───────────────────────────────────────────────────────

    private fun isPrinterDevice(device: UsbDevice): Boolean {
        // Check USB printer class (7) on any interface
        for (i in 0 until device.interfaceCount) {
            if (device.getInterface(i).interfaceClass == UsbConstants.USB_CLASS_PRINTER) {
                return true
            }
        }
        // Check known thermal printer VIDs
        if (device.vendorId in PRINTER_VIDS) return true
        // Fallback: any device with a bulk-out endpoint that's not a hub/keyboard/mouse
        val excludedClasses = setOf(
            UsbConstants.USB_CLASS_HUB,
            UsbConstants.USB_CLASS_HID,
            UsbConstants.USB_CLASS_AUDIO,
            UsbConstants.USB_CLASS_VIDEO,
        )
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            if (intf.interfaceClass in excludedClasses) continue
            for (j in 0 until intf.endpointCount) {
                val ep = intf.getEndpoint(j)
                if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                    ep.direction == UsbConstants.USB_DIR_OUT) return true
            }
        }
        return false
    }

    private fun findPrinterDevice(): UsbDevice? {
        val devices = usbManager?.deviceList ?: return null
        return devices.values.firstOrNull { isPrinterDevice(it) }
    }

    private fun listPrinters(result: Result) {
        val devices = usbManager?.deviceList ?: run { result.success(emptyList<Any>()); return }
        val printers = devices.values
            .filter { isPrinterDevice(it) }
            .map { device ->
                mapOf(
                    "name"          to device.deviceName,
                    "vendorId"      to device.vendorId,
                    "productId"     to device.productId,
                    "manufacturer"  to (device.manufacturerName ?: ""),
                    "product"       to (device.productName ?: ""),
                    "hasPermission" to (usbManager?.hasPermission(device) ?: false),
                )
            }
        result.success(printers)
    }

    // ── Permission ─────────────────────────────────────────────────────────────

    private fun requestPermission(deviceName: String, result: Result) {
        val device = usbManager?.deviceList?.get(deviceName)
            ?: return result.error("NOT_FOUND", "Device not found: $deviceName", null)

        if (usbManager?.hasPermission(device) == true) {
            result.success(true)
            return
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT

        val permIntent = PendingIntent.getBroadcast(
            context, 0, Intent(ACTION_USB_PERMISSION), flags
        )

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                if (ACTION_USB_PERMISSION == intent.action) {
                    try { ctx.unregisterReceiver(this) } catch (_: Exception) {}
                    val granted = intent.getBooleanExtra(
                        UsbManager.EXTRA_PERMISSION_GRANTED, false
                    )
                    result.success(granted)
                }
            }
        }

        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, filter)
        }

        usbManager?.requestPermission(device, permIntent)
    }

    // ── Printing ───────────────────────────────────────────────────────────────

    private fun printBytes(deviceName: String, data: ByteArray, result: Result) {
        val device = usbManager?.deviceList?.get(deviceName)
            ?: return result.error("NOT_FOUND", "Device not found: $deviceName", null)

        if (usbManager?.hasPermission(device) != true) {
            return result.error("NO_PERMISSION", "USB permission not granted", null)
        }

        val connection = usbManager?.openDevice(device)
            ?: return result.error("OPEN_FAILED", "Could not open USB device", null)

        try {
            val (intf, bulkOut) = findBulkOutEndpoint(device)
                ?: run {
                    connection.close()
                    return result.error("NO_ENDPOINT", "No bulk-out endpoint found", null)
                }

            connection.claimInterface(intf, true)

            // Send data in chunks
            val chunkSize = bulkOut.maxPacketSize.coerceIn(64, 16384)
            var offset = 0
            while (offset < data.size) {
                val length = minOf(chunkSize, data.size - offset)
                val sent = connection.bulkTransfer(bulkOut, data, offset, length, 5000)
                if (sent < 0) {
                    connection.releaseInterface(intf)
                    connection.close()
                    return result.error("SEND_FAILED", "bulkTransfer failed at offset $offset", null)
                }
                offset += sent
            }

            connection.releaseInterface(intf)
            connection.close()
            result.success(true)

        } catch (e: Exception) {
            try { connection.close() } catch (_: Exception) {}
            result.error("EXCEPTION", e.message ?: "Unknown error", null)
        }
    }

    /** Returns diagnostic info about all connected USB devices. */
    private fun diagnose(result: Result) {
        val devices = usbManager?.deviceList ?: run { result.success("No USB devices found"); return }
        val sb = StringBuilder()
        sb.appendLine("USB devices: ${devices.size}")
        for (dev in devices.values) {
            sb.appendLine("---")
            sb.appendLine("Name: ${dev.deviceName}")
            sb.appendLine("VID: 0x${dev.vendorId.toString(16).uppercase()} (${dev.vendorId})")
            sb.appendLine("PID: 0x${dev.productId.toString(16).uppercase()} (${dev.productId})")
            sb.appendLine("Mfr: ${dev.manufacturerName ?: "?"}")
            sb.appendLine("Product: ${dev.productName ?: "?"}")
            sb.appendLine("Class: ${dev.deviceClass}")
            sb.appendLine("HasPermission: ${usbManager?.hasPermission(dev)}")
            sb.appendLine("Interfaces: ${dev.interfaceCount}")
            for (i in 0 until dev.interfaceCount) {
                val intf = dev.getInterface(i)
                sb.appendLine("  Intf[$i] class=${intf.interfaceClass} eps=${intf.endpointCount}")
                for (j in 0 until intf.endpointCount) {
                    val ep = intf.getEndpoint(j)
                    val dir = if (ep.direction == UsbConstants.USB_DIR_OUT) "OUT" else "IN"
                    val type = when (ep.type) {
                        UsbConstants.USB_ENDPOINT_XFER_BULK -> "BULK"
                        UsbConstants.USB_ENDPOINT_XFER_INT  -> "INT"
                        UsbConstants.USB_ENDPOINT_XFER_ISOC -> "ISOC"
                        else -> "CTRL"
                    }
                    sb.appendLine("    EP[$j] $type $dir maxPkt=${ep.maxPacketSize}")
                }
            }
        }
        result.success(sb.toString())
    }

    /** Find the first interface with a bulk-out endpoint, prioritising printer class. */
    private fun findBulkOutEndpoint(device: UsbDevice): Pair<UsbInterface, UsbEndpoint>? {
        // Priority 1: USB printer class interface
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            if (intf.interfaceClass == UsbConstants.USB_CLASS_PRINTER) {
                findBulkOut(intf)?.let { return Pair(intf, it) }
            }
        }
        // Priority 2: any interface with bulk-out
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            findBulkOut(intf)?.let { return Pair(intf, it) }
        }
        return null
    }

    private fun findBulkOut(intf: UsbInterface): UsbEndpoint? {
        for (j in 0 until intf.endpointCount) {
            val ep = intf.getEndpoint(j)
            if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                ep.direction == UsbConstants.USB_DIR_OUT
            ) return ep
        }
        return null
    }
}
