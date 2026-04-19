class WebNewsArticle {
  const WebNewsArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    this.featuredImage,
    required this.published,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String? featuredImage;
  final bool published;
  final DateTime createdAt;

  factory WebNewsArticle.fromJson(Map<String, dynamic> json) {
    return WebNewsArticle(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      featuredImage: json['featuredImage']?.toString(),
      published: _parseBool(json['isPublished'] ?? json['published']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'excerpt': excerpt,
        'content': content,
        if (featuredImage != null) 'featuredImage': featuredImage,
        'published': published,
      };

  WebNewsArticle copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? content,
    String? featuredImage,
    bool? published,
    DateTime? createdAt,
  }) {
    return WebNewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      featuredImage: featuredImage ?? this.featuredImage,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WebEvent {
  const WebEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.featuredImage,
    required this.published,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? featuredImage;
  final bool published;

  factory WebEvent.fromJson(Map<String, dynamic> json) {
    return WebEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      startDate: _parseDate(json['startDate'] ?? json['start_date']),
      endDate: _parseDate(json['endDate'] ?? json['end_date']),
      location: (json['location'] ?? '').toString(),
      featuredImage: json['featuredImage']?.toString(),
      published: _parseBool(json['isPublished'] ?? json['published']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'location': location,
        if (featuredImage != null) 'featuredImage': featuredImage,
        'published': published,
      };

  WebEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? featuredImage,
    bool? published,
  }) {
    return WebEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      featuredImage: featuredImage ?? this.featuredImage,
      published: published ?? this.published,
    );
  }
}

class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    required this.photoCount,
  });

  final String id;
  final String title;
  final String description;
  final String? coverImage;
  final int photoCount;

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      // coverImage may be a Cloudinary path or full URL
      coverImage: json['coverImage']?.toString(),
      photoCount: _parseInt(
          json['photoCount'] ?? json['_count']?['photos'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (coverImage != null) 'coverImage': coverImage,
      };

  GalleryAlbum copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImage,
    int? photoCount,
  }) {
    return GalleryAlbum(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      photoCount: photoCount ?? this.photoCount,
    );
  }
}

class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    required this.url,
    required this.caption,
    required this.albumId,
  });

  final String id;
  final String url;
  final String caption;
  final String albumId;

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      id: (json['id'] ?? '').toString(),
      // API stores as imagePath (Cloudinary URL or path)
      url: (json['imagePath'] ?? json['url'] ?? json['imageUrl'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      albumId: (json['albumId'] ?? json['album_id'] ?? '').toString(),
    );
  }
}

class WebTestimonial {
  const WebTestimonial({
    required this.id,
    required this.personName,
    required this.personRole,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    required this.published,
    required this.displayOrder,
  });

  final String id;
  final String personName;
  final String personRole;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final bool published;
  final int displayOrder;

  factory WebTestimonial.fromJson(Map<String, dynamic> json) {
    return WebTestimonial(
      id: (json['id'] ?? '').toString(),
      personName: (json['personName'] ?? json['person_name'] ?? '').toString(),
      personRole: (json['personRole'] ?? json['role'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? json['video_url'] ?? '').toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? json['thumbnail_url'])?.toString(),
      caption: (json['caption'] ?? '').toString(),
      published: _parseBool(json['isPublished'] ?? json['published']),
      displayOrder: _parseInt(json['displayOrder'] ?? json['display_order'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'personName': personName,
        'role': personRole,
        'videoUrl': videoUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'published': published,
        'displayOrder': displayOrder,
      };

  WebTestimonial copyWith({
    String? id,
    String? personName,
    String? personRole,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    bool? published,
    int? displayOrder,
  }) {
    return WebTestimonial(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      personRole: personRole ?? this.personRole,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      published: published ?? this.published,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class WebPage {
  const WebPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.metaTitle,
    required this.metaDescription,
    required this.published,
  });

  final String id;
  final String title;
  final String slug;
  final String content;
  final String metaTitle;
  final String metaDescription;
  final bool published;

  factory WebPage.fromJson(Map<String, dynamic> json) {
    return WebPage(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      metaTitle: (json['metaTitle'] ?? json['meta_title'] ?? '').toString(),
      metaDescription:
          (json['metaDescription'] ?? json['meta_description'] ?? '').toString(),
      published: _parseBool(json['isPublished'] ?? json['published']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'slug': slug,
        'content': content,
        'metaTitle': metaTitle,
        'metaDescription': metaDescription,
        'published': published,
      };

  WebPage copyWith({
    String? id,
    String? title,
    String? slug,
    String? content,
    String? metaTitle,
    String? metaDescription,
    bool? published,
  }) {
    return WebPage(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      published: published ?? this.published,
    );
  }
}

class WebsiteSettings {
  const WebsiteSettings({
    required this.schoolName,
    required this.schoolInitials,
    required this.tagline,
    this.logo,
    this.heroImage,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.facebook,
    required this.instagram,
    required this.youtube,
    required this.twitter,
    required this.studentCount,
    required this.facultyCount,
    required this.batchCount,
    required this.board,
    required this.mapEmbedUrl,
  });

  final String schoolName;
  final String schoolInitials;
  final String tagline;
  final String? logo;
  final String? heroImage;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String facebook;
  final String instagram;
  final String youtube;
  final String twitter;
  final String studentCount;
  final String facultyCount;
  final String batchCount;
  final String board;
  final String mapEmbedUrl;

  factory WebsiteSettings.fromJson(Map<String, dynamic> json) {
    // API field names (from /api/web-admin/website-settings):
    //   name, initials, tagline, email, contactNumbers (array),
    //   address, city, state, pincode, logoPath,
    //   facebookUrl, instagramUrl, youtubeUrl, twitterUrl, whatsappNumber
    //   statsStudents, statsFaculty, statsBatches, statsBoard, mapEmbedUrl
    final phones = json['contactNumbers'];
    final phoneStr = phones is List && phones.isNotEmpty
        ? phones.first.toString()
        : (json['contactPhone'] ?? '').toString();

    return WebsiteSettings(
      schoolName: (json['name'] ?? json['schoolName'] ?? '').toString(),
      schoolInitials: (json['initials'] ?? json['schoolInitials'] ?? '').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      logo: (json['logoPath'] ?? json['logo'])?.toString(),
      heroImage: json['heroImage']?.toString(),
      contactEmail: (json['email'] ?? json['contactEmail'] ?? '').toString(),
      contactPhone: phoneStr,
      address: (json['address'] ?? '').toString(),
      facebook: (json['facebookUrl'] ?? json['facebook'] ?? '').toString(),
      instagram: (json['instagramUrl'] ?? json['instagram'] ?? '').toString(),
      youtube: (json['youtubeUrl'] ?? json['youtube'] ?? '').toString(),
      twitter: (json['twitterUrl'] ?? json['twitter'] ?? '').toString(),
      studentCount: (json['statsStudents'] ?? json['studentCount'] ?? '').toString(),
      facultyCount: (json['statsFaculty'] ?? json['facultyCount'] ?? '').toString(),
      batchCount: (json['statsBatches'] ?? json['batchCount'] ?? '').toString(),
      board: (json['statsBoard'] ?? json['board'] ?? '').toString(),
      mapEmbedUrl: (json['mapEmbedUrl'] ?? '').toString(),
    );
  }

  // toJson uses actual API field names for PATCH /api/web-admin/website-settings
  Map<String, dynamic> toJson() => {
        'name': schoolName,
        'initials': schoolInitials,
        'tagline': tagline,
        'email': contactEmail,
        'address': address,
        'facebookUrl': facebook,
        'instagramUrl': instagram,
        'youtubeUrl': youtube,
        'twitterUrl': twitter,
        'statsStudents': studentCount,
        'statsFaculty': facultyCount,
        'statsBatches': batchCount,
        'statsBoard': board,
        'mapEmbedUrl': mapEmbedUrl,
      };

  WebsiteSettings copyWith({
    String? schoolName,
    String? schoolInitials,
    String? tagline,
    String? logo,
    String? heroImage,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? facebook,
    String? instagram,
    String? youtube,
    String? twitter,
    String? studentCount,
    String? facultyCount,
    String? batchCount,
    String? board,
    String? mapEmbedUrl,
  }) {
    return WebsiteSettings(
      schoolName: schoolName ?? this.schoolName,
      schoolInitials: schoolInitials ?? this.schoolInitials,
      tagline: tagline ?? this.tagline,
      logo: logo ?? this.logo,
      heroImage: heroImage ?? this.heroImage,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      twitter: twitter ?? this.twitter,
      studentCount: studentCount ?? this.studentCount,
      facultyCount: facultyCount ?? this.facultyCount,
      batchCount: batchCount ?? this.batchCount,
      board: board ?? this.board,
      mapEmbedUrl: mapEmbedUrl ?? this.mapEmbedUrl,
    );
  }
}

class WebDashboardStats {
  const WebDashboardStats({
    required this.newsCount,
    required this.eventsCount,
    required this.albumCount,
    required this.pagesCount,
    required this.publishedNews,
    required this.publishedEvents,
    required this.recentNews,
  });

  final int newsCount;
  final int eventsCount;
  final int albumCount;
  final int pagesCount;
  final int publishedNews;
  final int publishedEvents;
  final List<WebNewsArticle> recentNews;

  factory WebDashboardStats.fromParts({
    required List<WebNewsArticle> news,
    required List<WebEvent> events,
    required List<GalleryAlbum> albums,
    required List<WebPage> pages,
  }) {
    return WebDashboardStats(
      newsCount: news.length,
      eventsCount: events.length,
      albumCount: albums.length,
      pagesCount: pages.length,
      publishedNews: news.where((n) => n.published).length,
      publishedEvents: events.where((e) => e.published).length,
      recentNews: news.take(5).toList(),
    );
  }
}

// ── Mandatory Disclosure models ───────────────────────────────────────────────

class MandatoryGeneralInfo {
  const MandatoryGeneralInfo({
    this.schoolName = '',
    this.affiliationNo = '',
    this.schoolCode = '',
    this.address = '',
    this.principalName = '',
    this.principalQualification = '',
    this.schoolEmail = '',
    this.contactNumbers = const [],
  });
  final String schoolName;
  final String affiliationNo;
  final String schoolCode;
  final String address;
  final String principalName;
  final String principalQualification;
  final String schoolEmail;
  final List<String> contactNumbers;

  factory MandatoryGeneralInfo.fromJson(Map<String, dynamic> json) {
    final nums = json['contactNumbers'];
    return MandatoryGeneralInfo(
      schoolName: (json['schoolName'] ?? '').toString(),
      affiliationNo: (json['affiliationNo'] ?? '').toString(),
      schoolCode: (json['schoolCode'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      principalName: (json['principalName'] ?? '').toString(),
      principalQualification: (json['principalQualification'] ?? '').toString(),
      schoolEmail: (json['schoolEmail'] ?? '').toString(),
      contactNumbers: nums is List ? nums.map((e) => e.toString()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'affiliationNo': affiliationNo,
        'schoolCode': schoolCode,
        'address': address,
        'principalName': principalName,
        'principalQualification': principalQualification,
        'schoolEmail': schoolEmail,
        'contactNumbers': contactNumbers,
      };
}

class MandatoryStaff {
  const MandatoryStaff({
    this.principalName = '',
    this.totalTeachers = 0,
    this.pgt,
    this.tgt,
    this.prt,
    this.teacherSectionRatio = '',
    this.specialEducator = '',
    this.counsellorDetails = '',
  });
  final String principalName;
  final int totalTeachers;
  final int? pgt;
  final int? tgt;
  final int? prt;
  final String teacherSectionRatio;
  final String specialEducator;
  final String counsellorDetails;

  factory MandatoryStaff.fromJson(Map<String, dynamic> json) => MandatoryStaff(
        principalName: (json['principalName'] ?? '').toString(),
        totalTeachers: _parseInt(json['totalTeachers'] ?? 0),
        pgt: json['pgt'] != null ? _parseInt(json['pgt']) : null,
        tgt: json['tgt'] != null ? _parseInt(json['tgt']) : null,
        prt: json['prt'] != null ? _parseInt(json['prt']) : null,
        teacherSectionRatio: (json['teacherSectionRatio'] ?? '').toString(),
        specialEducator: (json['specialEducator'] ?? '').toString(),
        counsellorDetails: (json['counsellorDetails'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'principalName': principalName,
        'totalTeachers': totalTeachers,
        if (pgt != null) 'pgt': pgt,
        if (tgt != null) 'tgt': tgt,
        if (prt != null) 'prt': prt,
        'teacherSectionRatio': teacherSectionRatio,
        'specialEducator': specialEducator,
        'counsellorDetails': counsellorDetails,
      };
}

class MandatoryInfrastructure {
  const MandatoryInfrastructure({
    this.campusArea = '',
    this.classroomCount,
    this.classroomSize = '',
    this.labCount,
    this.labSize = '',
    this.internetFacility = false,
    this.girlsToilets,
    this.boysToilets,
    this.youtubeLink = '',
  });
  final String campusArea;
  final int? classroomCount;
  final String classroomSize;
  final int? labCount;
  final String labSize;
  final bool internetFacility;
  final int? girlsToilets;
  final int? boysToilets;
  final String youtubeLink;

  factory MandatoryInfrastructure.fromJson(Map<String, dynamic> json) =>
      MandatoryInfrastructure(
        campusArea: (json['campusArea'] ?? '').toString(),
        classroomCount: json['classroomCount'] != null ? _parseInt(json['classroomCount']) : null,
        classroomSize: (json['classroomSize'] ?? '').toString(),
        labCount: json['labCount'] != null ? _parseInt(json['labCount']) : null,
        labSize: (json['labSize'] ?? '').toString(),
        internetFacility: _parseBool(json['internetFacility']),
        girlsToilets: json['girlsToilets'] != null ? _parseInt(json['girlsToilets']) : null,
        boysToilets: json['boysToilets'] != null ? _parseInt(json['boysToilets']) : null,
        youtubeLink: (json['youtubeLink'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'campusArea': campusArea,
        if (classroomCount != null) 'classroomCount': classroomCount,
        'classroomSize': classroomSize,
        if (labCount != null) 'labCount': labCount,
        'labSize': labSize,
        'internetFacility': internetFacility,
        if (girlsToilets != null) 'girlsToilets': girlsToilets,
        if (boysToilets != null) 'boysToilets': boysToilets,
        'youtubeLink': youtubeLink,
      };
}

class MandatoryResult {
  const MandatoryResult({
    required this.id,
    required this.className,
    required this.year,
    required this.registeredStudents,
    required this.studentsPassed,
    required this.passPercentage,
    this.remarks = '',
  });
  final String id;
  final String className;
  final String year;
  final int registeredStudents;
  final int studentsPassed;
  final double passPercentage;
  final String remarks;

  factory MandatoryResult.fromJson(Map<String, dynamic> json) => MandatoryResult(
        id: (json['id'] ?? '').toString(),
        className: (json['class'] ?? '').toString(),
        year: (json['year'] ?? '').toString(),
        registeredStudents: _parseInt(json['registeredStudents'] ?? 0),
        studentsPassed: _parseInt(json['studentsPassed'] ?? 0),
        passPercentage: (json['passPercentage'] as num?)?.toDouble() ?? 0.0,
        remarks: (json['remarks'] ?? '').toString(),
      );
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return false;
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}
