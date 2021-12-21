public with sharing class ResponseMessage {
    public String title;
    public String url;
    public String detailUrl;
    public String type;
    public String mediaId;
    public String description;
    
    public ResponseMessage(String title,String url, String detailUrl, String mediaId, String type, String description) {
        this.title = title;
        this.url = url;
        this.detailUrl = detailUrl;
        this.type = type;
        this.mediaId = mediaId;
        this.description = description;
    }
}