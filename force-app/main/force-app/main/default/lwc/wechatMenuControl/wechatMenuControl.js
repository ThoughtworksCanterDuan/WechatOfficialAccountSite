import { LightningElement } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';
import updateWechatMenu from '@salesforce/apex/WechatMenuController.updateWechatMenu';

export default class WechatMenuControl extends LightningElement {
    updateWechatResponseMessage = '准备修改公众号菜单栏';
    errors;
    wechatMenuUpdate() {
        updateWechatMenu().then(messageInfo => {
            this.updateWechatResponseMessage = messageInfo;
        }).catch(error => {
            this.errors = reduceErrors(error);
        })
    }
}