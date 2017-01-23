{% if theme.alipay || theme.wechatpay %}
<div style="padding: 10px 0; margin: 20px auto; width: 90%; text-align: center">
  <div>{{ theme.reward_comment }}</div>
  <button id="rewardButton", disable="enable", onclick="var qr = document.getElementById('QR'); if (qr.style.display === 'none') {qr.style.display='block';} else {qr.style.display='none'}", style="cursor: pointer; border: 0; outline: 0; border-radius: 100%; padding: 0; margin: 0; letter-spacing: normal; text-transform: none; text-indent: 0px; text-shadow: none">
    <span onmouseover="this.style.color='rgb(236,96,0)';this.style.background='rgb(204,204,204)'" onMouseOut="this.style.color='#fff';this.style.background='rgb(236,96,0)'" style="display: inline-block; width: 70px; height: 70px; border-radius: 100%; line-height: 81px; color: #fff; font: 400 35px/75px 'microsofty'; background: rgb(236,96,0)">赏</span>
  </button>
  <div id="QR" style="display: none;">
    {% if theme.wechatpay %}
      <div id="wechat" style="display: inline-block">
        <img id="wechat_qr" src="{{ theme.wechatpay }}" alt="{{ theme.author }} WeChat Pay" style="width: 200px; max-width: 100%; display: inline-block"/>
        <p>微信打赏</p>
      </div>
    {% endif %}
    {% if theme.alipay %}
      <div id="alipay" style="display: inline-block">
        <img id="alipay_qr" src="{{ theme.alipay }}" alt="{{ theme.author }} Alipay" style="width: 200px; max-width: 100%; display: inline-block"/>
        <p>支付宝打赏</p>
      </div>
    {% endif %}
  </div>
<div>
{% endif %}


<! -- 添加捐赠图标 -->
    <div class ="post-donate">
      <div id="donate_board" class="donate_bar center">
        <a id="btn_donate" class="btn_donate" href="javascript:;" title="Donate 打赏"></a>
        <span class="donate_txt">
           &uarr;<br>
           赏杯咖啡，持续写作！
        </span>
        <br>
      </div>  
    
    <!-- 支付宝打赏图案 -->
      <!--<div id="donate_guide" class="donate_bar center hidden">
          <a href="http://static.ixirong.com/pic/donate/alipay2.png" title="支付宝打赏" class="fancybox" rel="article0">
          <img src="http://static.ixirong.com/pic/donate/alipay2.png" title="支付宝打赏" height="164px" width="164px">
          </a> 
      </div>-->

    <!-- 微信打赏图案 -->
      <div id="donate_guide" class="donate_bar center hidden">
          <a href="http://www.imike.me/img/donate/wechatpay.png" title="微信打赏" class="fancybox" rel="article0"  >
          <img src="http://www.imike.me/img/donate/wechatpay.png" title="微信打赏" height="164px" width="164px">
          </a> 
      </div>
  
      <script type="text/javascript">
        document.getElementById('btn_donate').onclick = function(){
          $('#donate_board').addClass('hidden');
          $('#donate_guide').removeClass('hidden');
        }
      </script>
    </div>
<! -- 添加捐赠图标 -->