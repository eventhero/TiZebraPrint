var Zebra = require('io.eventhero.tizebraprint');

var win = Ti.UI.createWindow({
	backgroundColor:'#fff',
	title:'Printers',
});

var navWin = Ti.UI.iOS.createNavigationWindow({
	window:win,
});

var printerTable = Ti.UI.createTableView();
win.add(printerTable);

navWin.open();

var findPrinters = function(){
	printerTable.data = [];
	var rows = [{title:'Search Again'}];

	Zebra.findBluetoothPrinters({callback:function(e){
        if (!e.success) {
            alert(e.message);
            printerTable.data = rows;
            return;
        }
        
    	for (var i in e.printers) {
            // add the row
    		rows.push({
    			printer:e.printers[i],
    			title:e.printers[i].name,
    		});
    	}
        printerTable.data = rows;
	}});
	
	Zebra.findNetworkPrinters({callback:function(e){
        if (!e.success) {
            alert(e.message);
            printerTable.data = rows;
            return;
        }
        
    	for (var i in e.printers) {
    		rows.push({
    			printer:e.printers[i],
    			title:e.printers[i].name,
    		});
    	}
        printerTable.data = rows;
	}});
}

printerTable.addEventListener('click',function(e){
	if (!e.row.printer) {
		findPrinters();
	} else {
        var thisPrinter = e.row.printer;
        
		var d = Ti.UI.createOptionDialog({
			title:'Choose option to print:',
			options:['Image','PDF 1 Page','PDF All Pages','Cancel'],
		});
		d.addEventListener('click',function(c){
			if (c.index === 0) {
				// print image
				var imageFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.png');
				var imageBlob = imageFile.read();
				Zebra.print({
					image:imageBlob,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			} else if (c.index === 1) {
				// print first page
				var pdfFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.pdf');
				var pdfBlob = pdfFile.read();
				Zebra.print({
					pdf:pdfBlob,
					page:1,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			} else if (c.index === 2) {
				// print all pages
				var pdfFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.pdf');
				var pdfURL = pdfFile.resolve();
				Zebra.print({
					pdf:pdfURL,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			}
		});
        
        Zebra.selectPrinter({
            serialNumber:thisPrinter.serialNumber,
            ip:thisPrinter.ip,
            port:thisPrinter.port,
            callback:function(x){
                if (!x.success) {
                    alert(x.message);
                    return;
                }
                
                // get the status
                Zebra.getPrinterStatus({
/* we could specify the printer connection, but we already selected it
                    serialNumber:thisPrinter.serialNumber,
                    ip:thisPrinter.ip,
                    port:thisPrinter.port,
*/
                    callback:function(status){
                        Ti.API.info('printer status: '+JSON.stringify(status));
            
                        if (!status.success) {
                            alert(status.message);
                            return;
                        }

                		d.show();
                    }
                });
            }
        });
	}
});

findPrinters();