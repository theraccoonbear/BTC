$(function() {
	
	var $walletBar = $('#walletBar');
	var logged_in = $walletBar.length > 0;
	
	var $myData;
	var $dataList;
	var $lag;
	var $spread;
	
	
	
	var newMetricEntry = function(id, label) {
		var $me =  $('<div id="' + id + '"><strong>' + label + ':</strong> <span class="value"></span></div><br/>');
		$dataList.append($me);
		return $me.find('.value');
	}
	
	
	
	if (logged_in) {
		var cachedVals = {
			sell: -Math.random()
		};
		
		var autoPoll = function(o) {
			var ctxt = this;
			this.url = o.url;
			this.callback = o.callback;
			this.interval = o.interval;
			this.active = false;
			if (typeof this.interval === 'undefined') {
				this.interval = 10000;
			}
			
			this.pollAction = function() {
				if (ctxt.active) {
					return;
				}
				ctxt.active = true;
				$.getJSON(ctxt.url, function(d) {
					ctxt.active = false;
					ctxt.callback(d)
				});
			};
			
			this.intTime = setInterval(this.pollAction, this.interval);
			this.pollAction();
		};
		
		
		var goxPoll = new autoPoll({
			url: 'http://data.mtgox.com/api/2/BTCUSD/money/ticker',
			interval: 10000,
			callback: function(data) {
				if (data.result && data.result === 'success') {
					cachedVals.sell = parseFloat(data.data.sell.value);
				}
			}
		});
		
		var polling = {
			interval: null,
			
			start: function() {
				console.log("Polling started");
				polling.interval = setInterval(polling.poll, 10000);
				polling.poll();
			},
			
			stop: function() {
				console.log("Polling stopped");
				clearInterval(polling.interval);
			},
			
			poll: function() {
				$.getJSON('https://mtgox.com/api/1/generic/order/lag', function(data) {
					if (data.result && data.result === 'success') {
						$lag.html(data['return']['lag_secs']);
					}
				});
			}
		};
		
		
		
		////////
		
		$walletBar.prepend('<li id="currentValue"><strong>$0.00</strong></li>').prepend('<li>Value of my BTC:</li>');
		
		$myData = $('<div class="line" id="myData"><dl></dl></div>');
		
		$dataList = $myData.find('dl');
		
		$lag = newMetricEntry('lag', 'Trading Lag');
		//$spread = newMetricEntry('spread', 'Bid/Ask Spread');
		
		
		$('nav.mainNav').after($myData);
		var $curExch = $('#lastPrice span');
		var $curSell = $('#sellPrice');
		var $curBuy = $('#buyPrice');
		
		var $btcBal = $('#virtualCur span');
		var $curVal = $('#currentValue strong');
		var $cashOnHand = $('li .USD .amount');
		
		var logged_in = $cashOnHand.length > 0;
		
		
		var one_btc = 0.000001;
		var last_btc = 0;
		var usd_val = 0;
		var old_usd_val = 0;
		
		var coinValue = function() {	
			return cachedVals.sell;
		};
		
		var valueOf = function(btc) {
			return btc * coinValue();
		};
		
		var myBTCBalance = function() {
			return parseFloat($btcBal.html().replace(/[^0-9.]/, ''));
		};
		
		var myValue = function() {
			return valueOf(myBTCBalance());
		}
		
		var cashOnHand = function() {
			return parseFloat($cashOnHand.html().replace(/[^0-9.]/, ''));
		};
		
		var getWorth = function() {
			var exch = parseFloat($curExch.html().replace(/[^0-9.]/, ''));
			var bal = parseFloat($btcBal.html().replace(/[^0-9.]/, ''));
			var w = parseFloat(exch * bal)
			
			return w;
		};
		
		var getLastWorth = function() {
			var w = parseFloat($curVal.html().replace(/[^0-9.]/, ''));
			return w;
		};
		
		var spread = function() {
			var s = 0;
			if ($curBuy.length > 0 && $curSell.val) {
				s = $curBuy.val() - $curSell.val();
			}
			return s;
		}
	
		var updateWorth = function() {
			last_btc = one_btc;
			one_btc = coinValue();
			
			old_usd_val = usd_val;
			usd_val = myValue();
			
			if (last_btc !== one_btc && last_btc != 0) {
				var delta = one_btc - last_btc;
				
				var sign = delta > 0 ? '+' : '-';
				var dir = delta > 0 ? '_UP_' : 'DOWN';
				var percent = delta / last_btc * 100;	
				
				
				var delta_val = usd_val - old_usd_val;
				
				delta = Math.abs(delta);
				delta_val = Math.abs(delta_val);
				percent = Math.abs(percent);
				
				//var spreadDiff = Math.abs($curSell.val() - $curBuy.val());
				//var spreadPercent = spreadDiff / $curSell.val() * 100;
				//var spreadMsg = '$' + spreadDiff.toFixed(2) + ', ' + spreadPercent.toFixed(2) + '%';
				//console.log(spreadMsg);
				//$spread.html(spreadMsg);
				
				
				if (console && typeof console.log === 'function') {
					var msg = '';
					msg += 'Instantaneous change of ' + sign + percent.toFixed(5) + '%.  1 BTC went from $' + last_btc.toFixed(5) + ' to $' + one_btc.toFixed(5) + ' a $' + sign + delta.toFixed(5) + ' change.';
					msg += '  Worth is now $' + usd_val.toFixed(5) + ' ' + dir + ' from $' + old_usd_val.toFixed(5) + ' a $' + sign + delta_val.toFixed(5) + ' change.'
					msg += '  Buy/sell spread is $' + spread().toFixed(5) + '.';
					msg += '  -  ' + (new Date()).toString();
					console.log(msg);
				}
				
				var total = usd_val + cashOnHand();
				
				$curVal.html('$' + usd_val.toFixed(5) + ' ($' + total.toFixed(5) + ')');
				
			}
			
		};
		
		var initialWorth = getWorth();
		$curVal.html('$' + initialWorth.toFixed(5));
		updateWorth();
		
		var intTimer = setInterval(updateWorth, 250);
		
		polling.start();
		
		var reloadTimer = setTimeout(function() {
			window.location.reload(true); 
		}, 600000)
	}
});