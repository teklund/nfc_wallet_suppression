/// Enum representing the status of suppression for NFC wallet interaction.
///
/// - `notSuppressed`: The NFC wallet interaction is not suppressed.
/// - `suppressed`: The NFC wallet interaction is suppressed.
/// - `unavailable`: The NFC wallet interaction suppression is unavailable.
/// - `denied`: The NFC wallet interaction suppression was denied.
/// - `cancelled`: The NFC wallet interaction suppression was cancelled.
/// - `notSupported`: The NFC wallet interaction suppression is not supported.
/// - `alreadyPresenting`: The NFC wallet interaction is already presenting.
/// - `unknown`: The NFC wallet interaction suppression status is unknown.
///
/// This enum provides a structured way to represent different states
/// related to the suppression of NFC wallet interactions.
enum SuppressionStatus {
  /// `notSuppressed`: The NFC wallet interaction is not suppressed.
  notSuppressed,

  /// `suppressed`: The NFC wallet interaction is suppressed.
  suppressed,

  /// `unavailable`: The NFC wallet interaction suppression is unavailable.
  unavailable,

  /// `denied`: The NFC wallet interaction suppression was denied.
  denied,

  /// `cancelled`: The NFC wallet interaction suppression was cancelled.
  cancelled,

  /// `notSupported`: The NFC wallet interaction suppression is not supported.
  notSupported,

  /// `alreadyPresenting`: The NFC wallet interaction is already presenting.
  alreadyPresenting,

  /// `unknown`: The NFC wallet interaction suppression status is unknown.
  unknown,
}
