#!/home/mingo/bin/squilu

/*
===================
Jump to the function handle_request for the main specification implementation
===================
*/

//foreach(idx, arg in vargv) print(arg.tostring(), "\t", arg);
APP_CODE_FOLDER <- (vargv.len() > 1) ? vargv[1] : (os.getenv("HOME") + "/bin/squiluLib");
APP_RUN_FOLDER <- (vargv.len() > 2) ? vargv[2] : os.getenv("PWD");
http_ports <- (vargv.len() > 3) ? vargv[3] : "8086,8087s";
AT_DEV_DBG <- (vargv.len() > 4) ? (vargv[4] == "true") : true;
APP_ROOT_FOLDER <- (vargv.len() > 5) ? vargv[5] : APP_RUN_FOLDER + "/s";
num_threads <- (vargv.len() > 6) ? vargv[6].tointeger() : 1;

//for-each-thread-start

__max_print_stack_str_size <- 1000;

local trget = table_rawget;
local trset = table_rawset;

local mime_types_table = {
  ".html" =  "text/html",
  ".htm" =  "text/html",
  ".shtm" =  "text/html",
  ".shtml" =  "text/html",
  ".css" =  "text/css",
  ".js" =   "application/x-javascript",
  ".ico" =  "image/x-icon",
  ".gif" =  "image/gif",
  ".jpg" =  "image/jpeg",
  ".jpeg" =  "image/jpeg",
  ".png" =  "image/png",
  ".svg" =  "image/svg+xml",
  ".txt" =  "text/plain",
  ".torrent" =  "application/x-bittorrent",
  ".wav" =  "audio/x-wav",
  ".mp3" =  "audio/x-mp3",
  ".mid" =  "audio/mid",
  ".m3u" =  "audio/x-mpegurl",
  ".ogg" =  "audio/ogg",
  ".ram" =  "audio/x-pn-realaudio",
  ".xml" =  "text/xml",
  ".json" =   "text/json",
  ".xslt" =  "application/xml",
  ".xsl" =  "application/xml",
  ".ra" =   "audio/x-pn-realaudio",
  ".doc" =  "application/msword",
  ".exe" =  "application/octet-stream",
  ".zip" =  "application/x-zip-compressed",
  ".xls" =  "application/excel",
  ".tgz" =  "application/x-tar-gz",
  ".tar" =  "application/x-tar",
  ".gz" =   "application/x-gunzip",
  ".arj" =  "application/x-arj-compressed",
  ".rar" =  "application/x-arj-compressed",
  ".rtf" =  "application/rtf",
  ".pdf" =  "application/pdf",
  ".swf" =  "application/x-shockwave-flash",
  ".mpg" =  "video/mpeg",
  ".webm" =  "video/webm",
  ".mpeg" =  "video/mpeg",
  ".mp4" =  "video/mp4",
  ".m4v" =  "video/x-m4v",
  ".asf" =  "video/x-ms-asf",
  ".avi" =  "video/x-msvideo",
  ".bmp" =  "image/bmp",
  ".apk" =  "application/vnd.android.package-archive",
  ".manifest" =  "text/cache-manifest",
};

local getMimeType(fn)
{
	local result = "application/octet-stream";
	local ext = fn.match("%.[^.]+$");
	if(ext)
	{
		local mt = trget(mime_types_table, ext, false);
		if(mt) result = mt;
	}
	return result;
}

local function time_stamp(){
	return os.date("!%Y-%m-%d %H:%M:%S");
}

/* Convert time_t to a string. According to RFC2616, Sec 14.18, this must be
 * included in all responses other than 100, 101, 5xx. */
local function gmt_time_string(tm=null)
{
	if (tm) return os.date("!%a, %d %b %Y %H:%M:%S GMT", tm);
	return os.date("!%a, %d %b %Y %H:%M:%S GMT");
}

local globals = getroottable();
local WIN32 = os.getenv("WINDIR") != null;
local ANDROID = table_rawget(globals, "jniLog", false);

//#include "../lib/sqlar.nut"
//#include "/home/mingo/bin/squiluLib/sqlar.nut"

//sqpcre2.loadlib("/home/mingo/dev/c/A_libs/pcre2-10.20/.libs/libpcre2-8.so");

local mg;

//auto escape_html_chars_list = " &<>\"'`!@$%()=+{}[]";
auto escape_html_chars_re = "([ &<>\"'`!@$%()=+{}[%]])";

function escapeHtml ( str ){
	if (str){
		return str.gsub(escape_html_chars_re, function(m){ return format("&#x%x;", m[0]);});
	}
}

function unescapeHtml ( str ){
	if (str){
		return str.gsub("(&[^;]-;)", function(m){
			auto n = m.match("&#x(%x%x);");
			if(n) return n.tointeger(16).tochar();
			if(m == "&lt;") return "<";
			if(m == "&bt;") return ">";
			if(m == "&amp;") return "&";
			if(m == "&quote;") return "\"";
			return "??";
		});
	}
}

local http_session;
//local my_respose_200_format_str = false;
local function get_response_headers_str(content_type="text/html", withBodyFmt=true)
{
	local my_respose_200_format_str = false;
	//if(!my_respose_200_format_str)
	{
		//local domain = session_pkg.http_session_host;
		//if(domain) domain = domain.split(':')[0];
		//else domain = "";
		//local expiration = " Expires=Wed, 01 May 2019 00:00:00 GMT;";
		local expiration = " Max-Age=31536000;";
		my_respose_200_format_str = "HTTP/1.1 200 OK\r\nContent-Type: " + content_type + "; charset=utf-8;\r\nCache-Control: no-cache,no-store\r\nContent-Length: %d\r\n";
		if(http_session && session_pkg.SESSION_COOKIE)
		{
			my_respose_200_format_str += "Set-Cookie: " +
				session_pkg.SESSION_COOKIE + "=" + session_pkg.http_session_id + 
					"; Path=/api/; " + expiration + " HttpOnly;\r\nSet-Cookie: " + 
				session_pkg.SESSION_COOKIE_SIGNATURE + "=" + session_pkg.http_session_id_signature + 
					"; Path=/api/; " + expiration + " HttpOnly;\r\n";
		}
		if(withBodyFmt) my_respose_200_format_str += "\r\n%s";
	}
	return my_respose_200_format_str;
}

local function sendContent(request, content_type, response_body, extra_header="\r\n")
{
	local resp_fmt = get_response_headers_str(content_type, false);
	local resp = format(resp_fmt, response_body.len()) + extra_header;
	request.print(resp);
	if(::type(response_body) == "string") request.print(response_body);
	else request.write_blob(response_body);
	return true;
}

local function sendJsonContent(request, response_body)
{
	return sendContent(request, "application/json", response_body);
}

local function sendBlobContent(request, response_body, content_type="application/octet-stream")
{
	return sendContent(request, content_type, response_body);
}

local function sendPdfContent(request, response_body, fn, asInline=true)
{
	auto content_disposition = format("Content-Transfer-Encoding: binary\r\nContent-Disposition: %s; filename=%s\r\n\r\n",
		asInline ? "inline" : "attachment", fn);
	return sendContent(request, "application/pdf", response_body, content_disposition);
}

local function sendHtmlContent(request, response_body)
{
	return sendContent(request, "text/html", response_body);
}

local function send_http_error_500(request, err_msg)
{
	if(AT_DEV_DBG) {
		foreach(k,v in get_last_stackinfo()) debug_print("\n", k, ":", v);
		debug_print("\n", err_msg, "\n")
	}
	local response = format("HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %d\r\n\r\n%s", 
		err_msg.len(),  err_msg);
	request.write(response, response.len());
	return true;
}

local function send_http_error_401(request, err_msg)
{
	if(AT_DEV_DBG) {
		foreach(k,v in get_last_stackinfo()) debug_print("\n", k, ":", v);
		debug_print("\n", err_msg, "\n")
	}
	local response = format("HTTP/1.1 401 Unauthorized\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: %d\r\n\r\n%s", 
		err_msg.len(),  err_msg);
	request.write(response, response.len());
	return true;
}

function json2var(json) {
	local vm = SlaveVM();
	local slave_func = "getTable";
	
	//debug_print(json, "\n");
	//convert new data from json to squilu table for merge
	vm.compilestring(slave_func, "return " + json);
	local tbl = vm.call(true, slave_func);
	return tbl;
}

auto products_list = readfile("products.json");
products_list = json2var(products_list);
products_list = products_list.products;

auto users_list = readfile("users.json");
users_list = json2var(users_list);

//
// Post
//
function split_filename(path){
  local result;
  path.gmatch("[/\\]?([^/\\]+)$", function(m){
	result = m;
	return false;
  });
  return result;
}

function form_url_insert_field (dest, key, value){
  local fld = table_rawget(dest, key, null);
  if (!fld) dest[key] <- value;
  else
  {
	if (type (fld) == "array") fld.push(value);
	else  dest[key] <- [fld, value];
  }
}

function multipart_data_get_field_names(headers, name_value){
  //foreach(k,v in headers) debug_print(k, "::", v, "\n");
  local disp_header = headers["content-disposition"] || "";
  local attrs = {};
  disp_header.gmatch(";%s*([^%s=]+)=\"(.-)\"", function(attr, val) {
	attrs[attr] <- val;
	//debug_print(attr, "::", val, "\n");
	return true;
  });
  name_value.push(attrs.name);
  name_value.push(table_rawget(attrs, "filename", false) ? split_filename(attrs.filename) : null);
}

function multipart_data_break_headers(header_data){
	local headers = {};
	header_data.gmatch("([^%c%s:]+):%s+([^\n]+)", function(type, val){
		headers[type.tolower()] <- val;
		return true;
	});
	return headers;
}

function multipart_data_read_field_headers(input, state){
	local s, e, pos = state.pos;
	input.find_lua("\r\n\r\n", function(start, end){s=start; e=end; return false;}, pos, true);
	if( s ) {
		state.pos <- e;
		return multipart_data_break_headers(input.slice(pos, s));
	}
	else return null;
}

function multipart_data_read_field_contents(input, state){
	local boundaryline = "\r\n" + state.boundary;
	local s, e, pos = state.pos;
	input.find_lua(boundaryline, function(start, end){ s=start; e=end; return false;}, pos, true)
	if (s) {
		state.pos <- e;
		state.size <- s-pos;
		return input.slice(pos, s);
	}
	else {
		state.size <- 0;
		return null;
	}
}

function multipart_data_file_value(file_contents, file_name, file_size, headers){
  local value = { contents = file_contents, name = file_name, size = file_size };
  foreach( h, v in headers) {
	if (h != "content-disposition") value[h] <- v;
  }
  return value;
}

function multipart_data_parse_field(input, state){
	local headers, value;

	headers = multipart_data_read_field_headers(input, state);
	if (headers) {
		local name_value=[];
		multipart_data_get_field_names(headers, name_value);
		if (name_value[1]) { //file_name
			value = multipart_data_read_field_contents(input, state);
			value = multipart_data_file_value(value, name_value[1], state.size, headers);
			name_value[1] = value;
		}
		else name_value[1] = multipart_data_read_field_contents(input, state)
		return name_value;
	}
	return null;
}

function multipart_data_get_boundary(content_type){
	local boundary;
	content_type.gmatch("boundary%=(.-)$", function(m){
		boundary = m;
		return false;
	});
	return "--" + boundary;
}

function parse_multipart_data(input, input_type, tab=null){
	if(!tab) tab = {};
	local state = {};
	state.boundary <- multipart_data_get_boundary(input_type);
	input.find_lua(state.boundary, function(start, end){state.pos <- end+1;return false;}, 0, true);
	while(true){
		local name_value = multipart_data_parse_field(input, state);
		//debug_print("\nparse_multipart_data: ", name_value);
		if(!name_value) break;
		form_url_insert_field(tab, name_value[0], name_value[1]);
	}
	return tab;
}

function parse_qs(qs, tab=null){
	if(!tab) tab = {};
	if (type(qs) == "string") {
		//debug_print(qs)
		qs.gmatch("([^&=]+)=([^&=]*)&?", function(key,val){
			//debug_print(key, "->", val)
			form_url_insert_field(tab, url_decode(key), url_decode(val));
			return true;
		});
	}
	else if (qs) throw("Request error: invalid query string");

	return tab;
}

function parse_qs_to_table(qs, tab=null){
	if(!tab) tab = {};
	if (type(qs) == "string") {
		//debug_print(qs)
		qs.gmatch("([^&=]+)=([^&=]*)&?", function(key,val){
			//debug_print(key, "->", val)
			key = url_decode(key);
			tab[key] <- url_decode(val);
			return true;
		});
	}
	else if (qs) throw("Request error: invalid query string");

	return tab;
}

function parse_qs_to_table_k(qs, tab=null, tabk=null){
	if(!tab) tab = {};
	if(!tabk) tabk = [];
	if (type(qs) == "string") {
		qs.gmatch("([^&=]+)=([^&=]*)&?", function(key, val){
		//debug_print(key, "->", val)
			key = url_decode(key);
			tabk.push(key);
			tab[key] <- url_decode(val);
			return true;
		});
	}
	else if (qs) throw("Request error: invalid query string");
	return tab;
}

function parse_post_data(input_type, data, tab = null){
	if(!tab) tab = {};
	local length = data.len();
	if (input_type.find("x-www-form-urlencoded") >= 0) parse_qs(data, tab);
	else if (input_type.find("multipart/form-data") >= 0) parse_multipart_data(data, input_type, tab);
	else if (input_type.find("SLE") >= 0) {
		local vv = [];
		sle2vecOfvec(data, vv);
		if (vv.len() > 0) {
			local names = vv[0];
			local values = vv[1];
			for (local i=0, len = names.len(); i < len; ++i){
				tab[names[i]] <- values[i];
			}
		}
	}
	return tab;
}

function get_post_data(request, max_len=1024*1000){
	local data_len = (request.get_header("Content-Length") || "0").tointeger();
	//debug_print("\nget_post_fields: ", __LINE__, ":", data_len, ":", max_len);
	if (data_len > 0 && data_len <= max_len) {
		local data = request.read(data_len);
		return data;
	}
	return null;
}

function get_post_fields(request, max_len=1024*1000, post_fields=false){
	local data_len = (request.get_header("Content-Length") || "0").tointeger();
	if(!post_fields) post_fields = {};
	local data = get_post_data(request, max_len);
	if (data) {
		local content_type = request.get_header("Content-Type") || "x-www-form-urlencoded";
		if(content_type.find("application/json") >= 0){
			return data;
		}
		parse_post_data(content_type, data, post_fields);
	}
	return post_fields;
}

local function redirect_request(request, url)
{
    request.print(format("HTTP/1.1 302 Found\r\nLocation: http%s://%s/%s\r\n\r\n",
                request.info.is_ssl ? "s" : "", request.info.http_headers.Host, url))
}

local function show_request_params(request)
{
	request.print("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n\r\n")
	request.print("<html><body><h1>Request Info</h1><ul>")
	foreach(k, v in request.info) {
		if ("table" == type(v) ){
			request.print(format("<li><b>%s</b>:</li><ul>", k));
			foreach( k2, v2 in v){
				request.print(format("<li><b>%s</b>: %s</li>", k2, v2));
			}
			request.print("</ul>");
		}
		else request.print(format("<li><b>%s</b>: %s</li>", k, (v == NULL ? "" : v).tostring()));
	}
	request.print("</ul></body></html>");
	return true;
}

/*
=======================
Router and main code start here
=======================
*/

function handle_request(event, request)
{
	if(event == "MG_NEW_REQUEST"){
		//debug_print("\n", request.get_option("num_threads"), request.get_conn_buf());
		try {
			//debug_print("\nHttp :\n", request.info.uri);
			local request_uri = request.info.uri;
			
			if (request_uri == "/SQ/testParams" )
			{
				return show_request_params(request);
			}
			
			if (request_uri == "/index.html" || request_uri == "/" )
			{
				return sendHtmlContent(request, [==[
<h2>HackmeUP !</h2>
<ul>
<li><a href="/health-check">health-check</a></li>
<li><a href="/welcome">welcome</a></li>
<li><a href="/login">login</a></li>
<li><a href="/check-login">check-login</a></li>
<li><a href="/products">products</a></li>
<li><a href="/products?title=Apple">products?title=Apple</a></li>
<li><a href="/products?_sort=price&_order=asc">/products?_sort=price&_order=asc</a></li>
</ul>
				]==]);
				//return sendMarkdownContent(request, "Home.md");
			}

			if ( request_uri == "/health-check" )
			{
				//23 de marzo de 2019 10:15
				auto content = os.date("%d de %B de %Y %H:%M");
				return sendHtmlContent(request, content);
			}

			if ( request_uri == "/welcome" )
			{
				auto lang = request.get_header("Accept-Language");
				auto content = "Hello world! " + lang;
				if(lang.match(" es")) content = "¡Hola mundo! " + lang; 
				return sendHtmlContent(request, content);
			}

			if ( request_uri == "/login" )
			{
				auto content = [==[
<html>
<head>
</head>
<body>
<h2>Login</h2>
<form  method="post" action="/check-login">
<label>email: <input type="text" name="email"></label>
<br>
<label>password: <input type="password" name="password"></label>
<br>
<input type="submit" value="Send">
</form>
</body>
</html>
				]==];
				return sendHtmlContent(request, content);
			}

			if ( request_uri == "/check-login" )
			{
				auto content = [==[{status: “error”, code: 401, “message”: “User or password not found”}]==];
				 if( request.info.request_method == "POST" )
				{
					local post_fields =  get_post_fields(request);
					auto user_email = trget(post_fields, "email", null);
					auto user_password = trget(post_fields, "password", null);
					if(user_email && user_password)
					{
						foreach(user in users_list)
						{
							if(user.email == user_email && user.password == user_password)
							{
								redirect_request(request, "welcome");
								return true;
							}
						}
					}
				}
				return send_http_error_401(request, content);
			}

			if ( request_uri == "/products" )
			{
				auto query_string =request.info.query_string;
				auto request_qs_table = query_string ? parse_qs_to_table(query_string) : {};
				auto title, _sort, _order;
				if(query_string)
				{
					title = trget(request_qs_table, "title", 0);
					_sort = trget(request_qs_table, "_sort", 0);
					_order = trget(request_qs_table, "_order", 0);
				}
				
				auto content = blob();
				content.write([==[
<html>
<head>
</head>
<body>
<h2>Products</h2>
<table>
<tr><th>Product</th><th>Price</th><th>Image</th></tr>
]==]);
				if(_sort && (_sort == "title" || _sort == "price"))
				{
					local function doSort(a, b)
					{
						if(_order && _order == "asc") return a[_sort] <=> b[_sort];
						return  b[_sort] <=> a[_sort];
					}
					products_list.sort(doSort);
				}
				
				foreach(prod in products_list)
				{
					if(title && title != prod.title) continue;
					content.write("<tr><td>", prod.title, "</td><td>Price: ", prod.price, 
						"</td><td><img src='" + prod.image_url.replace("http://json.hackmeup.io/images/", "/img/"), "' width='100px'></td></tr>");
				}

				content.write([==[
</table>
</body>
</html>
]==]);
				return sendHtmlContent(request, content.tostring());
			}

		}
		catch(exep){
			return send_http_error_500(request, exep);
		}
	}
	return false;
}

/*
=======================
Router and main code ends here
=======================
*/

//code for load/reload/debug start
local this_script_fn;

function setScriptFileName(fn)
{
	this_script_fn = fn;
}

function getScriptFileName()
{
	return this_script_fn;
}

function getCommonExtraCode(){
	local extra_code = "";
	
	local checkGlobal = function(gv)
	{
		if (table_rawin(globals, gv)){
			auto value = table_get(globals, gv);
			auto tvalue = type(value);
			if(tvalue == "string") extra_code += format(gv + " <- \"%s\";\n", value);
			else extra_code += format(gv + " <- %s;\n", value.tostring());
		} else extra_code += gv + " <- false;\n";
	}

	checkGlobal("APP_CODE_FOLDER");
	checkGlobal("APP_RUN_FOLDER");
	checkGlobal("APP_ROOT_FOLDER");
	checkGlobal("AT_DEV_DBG");

	//debug_print(extra_code);
	return extra_code;
}

function getThreadCode(sfn){
	local code = readfile(sfn);
	code = code.match("//for%-each%-thread%-start(.-)//for%-each%-thread%-end") +
		"\nsetScriptFileName(\"" + sfn + "\");\n";

	local extra_code = getCommonExtraCode();
	
	code = extra_code + "\n" + code;

	//debug_print(extra_code);
	//debug_print(code);
	return code;
}

function getUserCallbackSetup(sfn){
	local code = getThreadCode(sfn);	
	return compilestring( code, "webserver", true, 10 );
}
//code for load/reload/debug end

//for-each-thread-end

local mongoose_start_params = {
	error_log_file = "sq-mongoose.log",
	listening_ports = "127.0.0.1:9080",
	document_root = ".",
	num_threads = 1,
	//enable_tcp_nodelay = "yes",
	//cgi_extensions = "lua",
	//cgi_interpreter = "/usr/bin/lua",
	//cgi_interpreter = "C:\\Lua\\5.1\\lua.exe",
	ssl_certificate = "axTLS.x509_512.pem",
        //"ssl_certificate", "axTLS.x509_1024.pem",
        ssl_chain_file = "axTLS_x509_512.cer",
	extra_mime_types = ".xsl=application/xml",
	master_plugin = function(){
		debug_print("done master_plugin\n");
	},
	master_plugin_exit = function(){
		debug_print("done master_plugin_exit\n");
	},
	//functions to be used by each independent lua vm
	user_callback_setup = getUserCallbackSetup(vargv[0]),
	user_callback_exit = function(){
		debug_print("done user_callback_exit\n");
	},
	user_callback = function(event, request){
		if(AT_DEV_DBG) dostring(getThreadCode(getScriptFileName()));
		return handle_request(event, request);
	},
}

function appServerStart(port, document_root){
	print("Listening at", port, document_root);
	mg = Mongoose();
	mongoose_start_params.num_threads <- num_threads;
	mongoose_start_params.listening_ports = port;
	mongoose_start_params.document_root = document_root;
	mg.show_errors_on_stdout(true);
	mg.start(mongoose_start_params);
}

function appServerStop(){
	if(mg) {
		mg.stop();
		mg = null;
	}
}

appServerStart(http_ports, APP_ROOT_FOLDER);

if(WIN32 || ANDROID)
{
	stdin.readn('c');
}
else
{
	local SIGINT = os.signal_str2int("SIGINT");
	os.signal(SIGINT);

	local SIGQUIT = os.signal_str2int("SIGQUIT");
	//os.signal(SIGQUIT);

	local SIGTERM = os.signal_str2int("SIGTERM");
	//os.signal(SIGTERM);

	local SIGALRM = os.signal_str2int("SIGALRM");
	//os.signal(SIGALRM);

	local SIGHUP = os.signal_str2int("SIGHUP");
	//os.signal(SIGHUP);

	local run_loop = true;
	while(run_loop) {
		local signal_received = os.get_signal_received();
		if(signal_received) {
			local sig_name = os.signal_int2str(signal_received);
			switch(sig_name) {
				case "SIGINT":
				case "SIGQUIT":
				case "SIGTERM":
					run_loop = false;
				break;
				case "SIGALRM":
					run_loop = false;
				break;
				case "SIGHUP":
					run_loop = false;
				break;
			}
		}
		if(run_loop) {
			os.sleep(100);
		} else {
			print(signal_received, os.signal_int2str(signal_received));
		}
	}
}

appServerStop();

