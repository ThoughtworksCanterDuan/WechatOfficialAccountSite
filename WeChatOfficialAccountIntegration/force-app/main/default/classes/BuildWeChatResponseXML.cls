public class BuildWeChatResponseXML {
	public static String buildResponseXML(RequestMessage message,List<ResponseMessage> responseMessageList) {
        
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
}