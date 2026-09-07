// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation using browser window and blobs
void openHtmlContent(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
