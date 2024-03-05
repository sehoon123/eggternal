abstract class ContentItem {}

class TextContent extends ContentItem {
 final String text;

 TextContent(this.text);
}

class ImageContent extends ContentItem {
 final String imageUrl; // Assuming you're storing images as URLs

 ImageContent(this.imageUrl);
}