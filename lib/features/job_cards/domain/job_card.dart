import '../../auth/domain/auth_user.dart';

class JobCardStatus {
  const JobCardStatus._(this.value);

  final String value;

  static const draft = JobCardStatus._('DRAFT');
  static const open = JobCardStatus._('OPEN');
  static const assigned = JobCardStatus._('ASSIGNED');
  static const inProgress = JobCardStatus._('IN_PROGRESS');
  static const waitingForParts = JobCardStatus._('WAITING_FOR_PARTS');
  static const waitingForApproval = JobCardStatus._('WAITING_FOR_APPROVAL');
  static const completed = JobCardStatus._('COMPLETED');
  static const readyForPickup = JobCardStatus._('READY_FOR_PICKUP');
  static const closed = JobCardStatus._('CLOSED');
  static const cancelled = JobCardStatus._('CANCELLED');

  static const values = [
    draft,
    open,
    assigned,
    inProgress,
    waitingForParts,
    waitingForApproval,
    completed,
    readyForPickup,
    closed,
    cancelled,
  ];

  static JobCardStatus fromValue(Object? value) {
    return values.firstWhere((status) => status.value == value, orElse: () => draft);
  }

  bool canTransitionTo(JobCardStatus target, UserRole role) {
    if (target == cancelled) return role != UserRole.mechanic && this != closed;
    if (this == draft && target == open) return role != UserRole.mechanic;
    if (this == open && target == assigned) return role == UserRole.manager || role == UserRole.shopOwner;
    if (this == assigned && target == inProgress) return role == UserRole.mechanic || role == UserRole.manager || role == UserRole.shopOwner;
    if (this == inProgress && (target == waitingForParts || target == waitingForApproval || target == completed)) return true;
    if (this == waitingForParts && target == inProgress) return role == UserRole.mechanic || role == UserRole.manager || role == UserRole.shopOwner;
    if (this == waitingForApproval && target == completed) return role == UserRole.manager || role == UserRole.shopOwner;
    if (this == completed && target == readyForPickup) return role == UserRole.manager || role == UserRole.shopOwner;
    if (this == readyForPickup && target == closed) return role == UserRole.frontDesk || role == UserRole.manager || role == UserRole.shopOwner;
    return false;
  }
}

class JobCard {
  const JobCard({
    required this.jobCardId,
    required this.shopId,
    required this.jobNumber,
    required this.customerId,
    required this.vehicleId,
    required this.status,
    required this.priority,
    required this.complaint,
    required this.diagnosis,
    required this.repairNotes,
    required this.assignedMechanicIds,
    required this.createdBy,
    required this.approvedBy,
    required this.grandTotalMinorUnits,
    required this.openedAt,
    required this.updatedAt,
  });

  final String jobCardId;
  final String shopId;
  final String jobNumber;
  final String customerId;
  final String vehicleId;
  final JobCardStatus status;
  final String priority;
  final String complaint;
  final String? diagnosis;
  final String? repairNotes;
  final List<String> assignedMechanicIds;
  final String createdBy;
  final String? approvedBy;
  final int grandTotalMinorUnits;
  final DateTime? openedAt;
  final DateTime? updatedAt;

  factory JobCard.fromMap(String id, Map<String, dynamic> map) {
    DateTime? dateValue(Object? value) => value is DateTime ? value : null;
    final mechanicIds = map['assignedMechanicIds'];
    return JobCard(
      jobCardId: id,
      shopId: map['shopId'] as String? ?? '',
      jobNumber: map['jobNumber'] as String? ?? id,
      customerId: map['customerId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      status: JobCardStatus.fromValue(map['status']),
      priority: map['priority'] as String? ?? 'NORMAL',
      complaint: map['complaint'] as String? ?? '',
      diagnosis: map['diagnosis'] as String?,
      repairNotes: map['repairNotes'] as String?,
      assignedMechanicIds: mechanicIds is List ? mechanicIds.whereType<String>().toList() : const [],
      createdBy: map['createdBy'] as String? ?? '',
      approvedBy: map['approvedBy'] as String?,
      grandTotalMinorUnits: (map['grandTotalMinorUnits'] as num?)?.toInt() ?? 0,
      openedAt: dateValue(map['openedAt']),
      updatedAt: dateValue(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() => {
        'jobCardId': jobCardId,
        'shopId': shopId,
        'jobNumber': jobNumber,
        'customerId': customerId,
        'vehicleId': vehicleId,
        'status': status.value,
        'priority': priority,
        'complaint': complaint,
        'diagnosis': diagnosis,
        'repairNotes': repairNotes,
        'assignedMechanicIds': assignedMechanicIds,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'grandTotalMinorUnits': grandTotalMinorUnits,
      };
}
