@RestResource(urlMapping='/WeChatRest/*')
global without sharing class WeChatRestController  
{
    @HttpGet
    global static void validateSignature() {
        //获取微信端传递的参数
        String signature = RestContext.request.params.get('signature'); // 微信加密签名 
        String timestamp = RestContext.request.params.get('timestamp'); // 微信请求URL时传过来的timestamp值
        String nonce = RestContext.request.params.get('nonce'); // 随机数-->微信请求URL时传过来的nonce值
        String echostr = RestContext.request.params.get('echostr'); // 随机字符串
        //1. 字典排序
        String myToken = 'canterduan0222';
        List<String> paramList = new List<String>{myToken,timestamp,nonce};
        paramList.sort();
        String content = '';
        for(String param : paramList) {
            content += param;
        }
        // 2. sha1算法转换
        Blob hash = Crypto.generateDigest('SHA1', Blob.valueOf(content));  
        String hexString= EncodingUtil.convertToHex(hash);
        //3. 比对转换后的值是否和传递的echostr相同，相同证明认证通过
        Boolean isValid = hexString != null ? signature.equalsIgnoreCase(hexString) : false;
        
        if(isValid) {
            RestContext.response.addHeader('Content-Type', 'text/plain');
            RestContext.response.responseBody = Blob.valueOf(echostr);
        }
    }

    @HttpPost
    global static void doPost() {
    
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        string strMsg = req.requestBody.toString();
        system.debug('*** message from wechat : ' + strMsg);
        XmlStreamReader reader = new XmlStreamReader(strMsg);
        String toUserName = '';
        String fromUserName = '';
        String msgType = '';
        String content = '';
        
        //解析微信传递过来的XML，将主要的内容的值取出来并进行操作
        while(reader.hasNext()) {
            if(reader.getLocalName() == 'ToUserName') {
                reader.next();
                if(String.isNotBlank(reader.getText())) {
                    toUserName = reader.getText();
                }
            } else if(reader.getLocalName() == 'FromUserName') {
                reader.next();
                if(String.isNotBlank(reader.getText())) {
                    fromUserName = reader.getText();
                }
            } else if(reader.getLocalName() == 'MsgType') {
                reader.next();
                if(String.isNotBlank(reader.getText())) {
                    msgType = reader.getText();
                }
            } else if(reader.getLocalName() == 'Content') {
                reader.next();
                if(String.isNotBlank(reader.getText())) {
                    content = reader.getText();
                }
            }
            
            reader.next();
        }

        //封装到request bean中用于获取传递过来的关键字的值
        RequestMessage receiveMsg = new RequestMessage(toUserName,fromUserName,msgType,content);
        //返回到微信的XML格式类型的字符串
        String resultXML;
        
        //根据输入类型进行处理，目前公众号只支持文本类型
        if(msgType.equals('text')){  
           resultXML = buildResponseXMLByContent(receiveMsg);
        } else {
            resultXML = buildResponseXML(receiveMsg,null);
        }
        RestContext.response.addHeader('Content-Type', 'text/plain');  
        RestContext.response.responseBody = Blob.valueOf(resultXML);  
    }

    private static String buildResponseXMLByContent(RequestMessage message) {
        //用于作为XML拼装的返回结果
        String buildXMLString;
        
        //通过SOSL根据关键字进行搜索
        String keyword = '\'' + message.content + '\'';
        String soslString = 'FIND' + keyword + 'IN ALL FIELDS ' 
                                + ' RETURNING '
                                + ' knowledge_base__c(Title__c,Blog_URL__c,Picture_URL__c,Description__c,MsgType__c,Media_ID__c) LIMIT 1';

        List<List<SObject>> soslResultList = search.query(soslString);
        //对搜索出来的结果集进行封装，然后加工处理XML作为微信返回内容
        List<ResponseMessage> responseMessageList = new List<ResponseMessage>();


        List<knowledge_base__c> myKnowledgeList = new List<knowledge_base__c>();
        if(soslResultList.size() > 0) {
            myKnowledgeList = (List<knowledge_base__c>)soslResultList.get(0);
        }

        for(knowledge_base__c myKnowledge : myKnowledgeList) {
            ResponseMessage messageItem = new ResponseMessage(myKnowledge.Title__c,myKnowledge.Blog_URL__c,myKnowledge.Picture_URL__c,myKnowledge.Media_ID__c, myKnowledge.MsgType__c, myKnowledge.Description__c);
            responseMessageList.add(messageItem);
        }
        buildXMLString = buildResponseXML(message, responseMessageList);
        System.debug(LoggingLevel.INFO, '*** buildXMLString: ' + buildXMLString);
        return buildXMLString;
    }

    private static String buildResponseXML(RequestMessage message,List<ResponseMessage> responseMessageList) {
        
        // String newsTpl = '<item><Title><![CDATA[{0}]]></Title><Description><![CDATA[{1}]]></Description><PicUrl><![CDATA[{2}]]></PicUrl><Url><![CDATA[{3}]]></Url></item>';

        String currentDateTime = System.now().format('YYYY-MM-dd HH:mm:ss');

        //根据微信公众号规则拼装XML模板
        // String responseMessageTemplate = '<xml><ToUserName><![CDATA[{0}]]></ToUserName><FromUserName><![CDATA[{1}]]></FromUserName><CreateTime>' + currentDateTime + '</CreateTime><MsgType><![CDATA[{2}]]></MsgType>' + '<Content><![CDATA[{3}]]></Content>' +'</xml>';
        String responseMessageTemplate = '<xml><ToUserName><![CDATA[{0}]]></ToUserName><FromUserName><![CDATA[{1}]]></FromUserName><CreateTime>' + currentDateTime + '</CreateTime><MsgType><![CDATA[{2}]]></MsgType>' + '{3}' +'</xml>';
        //XML模板中对应的Placeholder的值
        String[] arguments;
        //非文本输入提示
        if(!message.msgType.equalsIgnoreCase('text')) {
            arguments = new String[]{message.fromUserName, message.toUserName, 'text', '<Content><![CDATA[该公众号目前支持文字输入，可尝试输入关键字“Salesforce”，“敏捷”，“自行车”]]></Content>'};
        } else {
            //没有搜索出记录提示
            if(responseMessageList.isEmpty()) {
                arguments = new String[]{message.fromUserName, message.toUserName, 'text', '<Content><![CDATA[没有匹配的数据，请重新尝试其他的关键字]]></Content>'};
            } else {
                ResponseMessage responseItem = responseMessageList[0];
                String returnMessageType = '';
                String showMessageContent = '';
                switch on responseItem.type {
                    when 'news'{
                        showMessageContent = '<ArticleCount>1</ArticleCount><Articles><item><Title><![CDATA['+responseItem.title+']]></Title><Description><![CDATA['+responseItem.description+']]></Description><PicUrl><![CDATA['+responseItem.detailUrl+']]></PicUrl><Url><![CDATA['+responseItem.url+']]></Url></item></Articles>';
                        returnMessageType = 'news';
                    }
                    when 'image'{
                        showMessageContent = '<Image><MediaId><![CDATA['+responseItem.mediaId+']]></MediaId></Image>';
                        returnMessageType = 'image';
                    }
                    when 'voice'{
                        showMessageContent = '<Voice><MediaId><![CDATA['+responseItem.mediaId+']]></MediaId></Voice>';
                        returnMessageType = 'voice';
                    }
                    when 'video'{
                        showMessageContent = '<Video><MediaId><![CDATA['+responseItem.mediaId+']]></MediaId><Title><![CDATA['+responseItem.title+']]></Title><Description><![CDATA['+responseItem.description+']]></Description></Video>';
                        returnMessageType = 'video';
                    }
                    when 'music'{
                        showMessageContent = '<Music><Title><![CDATA['+responseItem.title+']]></Title><Description><![CDATA['+responseItem.description+']]></Description><MusicUrl><![CDATA['+responseItem.title+']]></MusicUrl><HQMusicUrl><![CDATA[]]></HQMusicUrl><ThumbMediaId><![CDATA['+responseItem.mediaId+']]></ThumbMediaId></Music>';
                        returnMessageType = 'music';
                    }
                    when else {
                        String messageStringBuffer = '';
                        messageStringBuffer += '<a href="' + responseItem.url + '">' + responseItem.title + '"></a>\n';
                        messageStringBuffer = messageStringBuffer.removeEnd('\n');
                        showMessageContent = '<Content><![CDATA[' + messageStringBuffer + ']]></Content>';
                        returnMessageType = 'text';
                    }
                }
                arguments = new String[]{message.fromUserName, message.toUserName, returnMessageType, showMessageContent};
            }
        }     
        String results = String.format(responseMessageTemplate, arguments);
        return results;
    }

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
}