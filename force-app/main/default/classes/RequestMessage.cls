public with sharing class RequestMessage {
    public String toUserName;
    public String fromUserName;
    public String msgType;   
    public String content;
    
    public RequestMessage(String toUserName,String fromUserName,String msgType,String content) {
        this.toUserName = toUserName;
        this.fromUserName = fromUserName;
        this.msgType = msgType;
        this.content = content;
    }
}