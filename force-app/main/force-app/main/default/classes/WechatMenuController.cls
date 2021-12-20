public with sharing class WechatMenuController {
    @AuraEnabled(cacheable=true)
    public static String updateWechatMenu() {
        String accessToken = '51_MyG1XPozdMC-AN4hD_x6NPjdYcihDgC-awbwo36id7BT9un_qF-wZVuDwvNQP8kK8SxZbdz0b-5Nq0tGwIRBFzFum1qJcK4Dwlbif2iVoFkT6VnVS0Bw_XDNpPMf7SJZN0n0TAOapD-FafyhSLFhAHAATN'; //System.Label.wechatToken;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Accept-Encoding','gzip,deflate');
        req.setHeader('Content-Type','text/xml;charset=UTF-8');
        req.setHeader('User-Agent','Jakarta Commons-HttpClient/3.1');

        String xml = '{"button":[{"name":"关于我们","sub_button":[{"type":"click","name":"公司简介","key":"公司简介"},{"type":"click","name":"社会责任","key":"社会责任"}]},{"name":"技术支持","sub_button":[{"type":"click","name":"文档下载","key":"文档下载"},{"type":"click","name":"技术社区","key":"技术社区"}]}]}';

        req.setBody(xml);
        // 需要将“https://api.weixin.qq.com“设置为远程站点（remote site setting）
        // 目前自定义菜单接口不对“个人账号”以及“未进过微信认证”的微信公众号开发，所以无法调通。
        req.setEndpoint('https://api.weixin.qq.com/cgi-bin/menu/create?access_token=' + accessToken);
        String bodyRes = '';
        try
        {
            HttpResponse res = h.send(req);
            bodyRes = res.getBody();
        }
        catch(System.CalloutException e)
        {
            System.debug('Callout error: '+ e);
            bodyRes = 'Callout error: '+ e;
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
        }
        return bodyRes;
        
    }
}
