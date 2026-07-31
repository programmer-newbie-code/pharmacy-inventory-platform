/// Determines the priority order of pharmacy alerts.
///
/// Ordering (lowest value = highest priority):
/// 1. expired — product already past expiry
/// 2. expiring — within 30 days of expiry
/// 3. failedBackup — last backup attempt failed
/// 4. lowStock — below reorder threshold
/// 5. openShift — cashier shift still open after end of day
enum AlertPriority {
  expired(0),
  expiring(1),
  failedBackup(2),
  lowStock(3),
  openShift(4);

  const AlertPriority(this.priority);
  final int priority;

  bool get isCritical => priority <= 1;
}
