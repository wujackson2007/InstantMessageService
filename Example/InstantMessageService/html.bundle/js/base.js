String.prototype.trim = function () { return this.replace(/^\s\s*/, '').replace(/\s\s*$/, ''); };
String.prototype.ltrim = function () { return this.replace(/^\s+/, ''); };
String.prototype.rtrim = function () { return this.replace(/\s+$/, ''); };
String.prototype.left = function (n) { return this.substr(0, n); };
String.prototype.right = function (n) { return this.substr(this.length - n, n); };
String.prototype.format = function () {
    var O_VAL = this;

    for (var i = 0; i < arguments.length; i++) {
        var re = new RegExp("\\{" + i + "\\}", "g");
        O_VAL = O_VAL.replace(re, arguments[i]);
    }

    return O_VAL;
};

function invokeSrApi(URL) {
    location.href = URL;
}

function LoadFile(filename) {
    var as = undefined;
    if (filename.indexOf(".js") > -1) {
        as = document.createElement('script');
        as.type = 'text/javascript';
        as.async = true;
        as.src = filename;
        $('head').append(as);
    }
    else if (filename.indexOf(".css") > -1) {
        as = document.createElement("link");
        as.setAttribute("rel", "stylesheet");
        as.setAttribute("type", "text/css");
        as.setAttribute("href", filename);

        if (typeof as != "undefined")
            document.getElementsByTagName("head")[0].appendChild(as);
    }
}

function trace(arg) {
    if (arg != undefined)
        invokeSrApi('invoke://consoleLog?{consoleLog:[' + JSON.stringify(arg) + ']}');
}