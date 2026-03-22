abstract class VisionInterface {
  /// Returns a list of detected ingredient names from the given image path.
  Future<List<String>> detectIngredients(String imagePath);
}
