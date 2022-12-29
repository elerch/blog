+++
title = "Javascript Hacks: Using XHR to load binary data"
slug = "2009-07-07-javascript-hacks-using-xhr-to-load-binary-data"
published = 2009-07-07T10:56:00.001000-07:00
author = "Emil"
tags = [ "Javascript",]
+++
I recently needed to get image data from a server using Javascript,
base64 encode it, and post that data back to an application. While the
details of <span style="font-weight: bold;">why</span> I needed to do
this are a bit complex, I believe that getting image data through an
XMLHttpRequest object and base 64 enconding it will become more valuable
in terms of client-side image manipulation using the [data URI
scheme](http://en.wikipedia.org/wiki/Data_URI_scheme) for image tags.  
  
This would allow a Javascript developer, for instance, to load an
existing image (say, a photo), without base64 encoding it on the server,
load it into an image tag with a data URI, and make direct manipulations
on that image.  
  
Unfortunately, this area is relatively new and browsers have a lot of
differences. Data URI support is still very new, inconsistent, and
limited. In the meantime, here is how you get that base64 encoded image
in the first place:  
  
Internet Explorer:  

  
IE has a property of XMLHttpRequest object for binary data
[ResponseBody](http://msdn.microsoft.com/en-us/library/ms534368%28VS.85%29.aspx).
This contains exactly what we need, but unfortunately the property is
not visible to Javascript. Since the string returned to Javascript by
[ResponseText](http://msdn.microsoft.com/en-us/library/ms534369%28VS.85%29.aspx)
will be terminated at the first null value, we must use ResponseBody.
This requires a bit of VBScript, which can do one of the following
things:  

1.  Get the numeric value of each unsigned byte and turn that into a
    number in a string of comma delimited numbers. This is less
    efficient, but gets you in and out of VBScript as quickly as
    possible, allowing a generic base64 encoding routine. This is the
    route I followed (it may be less efficient, but it pales in
    comparison with the XHR request just made):  

        Function BinaryArrayToAscCSV( aBytes )
         Dim j, sOutput
                sOutput = "BinaryArrayToAscCSV"
         For j = 1 to LenB(aBytes)
          sOutput= sOutput & AscB( MidB(aBytes,j,1) )
          sOutput= sOutput & ","
         Next
         BinaryArrayToAscCSV = sOutput
        End Function

      

2.  Base 64 encode it directly in VBScript.

  
Once this is done, we can then base64 encode it using a fairly generic
function in Javascript:  

    Base64 = {
     
     // private property
     _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

     encodeBinaryArrayAsString : function(input){
      var ascArr;
      var output = "";
      var bytebuffer;
      var encodedCharIndexes = new Array(4);
      
      var inx = 0;
      ascArr = input.substring("BinaryArrayToAscCSV".length, input.length - 1).split(',');
      while(inx < ascArr.length){
       // Fill byte buffer array
       bytebuffer = new Array(3);
       for(jnx = 0; jnx < bytebuffer.length; jnx++)
        if(inx < ascArr.length)
         bytebuffer[jnx] = parseInt(ascArr[inx++]); 
        else
         bytebuffer[jnx] = 0;
         
       // Get each encoded character, 6 bits at a time
       // index 1: first 6 bits
       encodedCharIndexes[0] = bytebuffer[0] >> 2;  
       // index 2: second 6 bits (2 least significant bits from input byte 1 + 4 most significant bits from byte 2)
       encodedCharIndexes[1] = ((bytebuffer[0] & 0x3) << 4) | (bytebuffer[1] >> 4);  
       // index 3: third 6 bits (4 least significant bits from input byte 2 + 2 most significant bits from byte 3)
       encodedCharIndexes[2] = ((bytebuffer[1] & 0x0f) << 2) | (bytebuffer[2] >> 6);  
       // index 3: forth 6 bits (6 least significant bits from input byte 3)
       encodedCharIndexes[3] = bytebuffer[2] & 0x3f;  
       
       // Determine whether padding happened, and adjust accordingly
       paddingBytes = inx - (ascArr.length - 1);
       switch(paddingBytes){
        case 2:
         // Set last 2 characters to padding char
         encodedCharIndexes[3] = 64; 
         encodedCharIndexes[2] = 64; 
         break;
        case 1:
         // Set last character to padding char
         encodedCharIndexes[3] = 64; 
         break;
        default:
         break; // No padding - proceed
       }
       // Now we will grab each appropriate character out of our keystring
       // based on our index array and append it to the output string
       for(jnx = 0; jnx < encodedCharIndexes.length; jnx++)
        output += this._keyStr.charAt(encodedCharIndexes[jnx]);     
      }
      return output;
     }
    };

  
  
  
Firefox:  

  
Firefox works a little differently, as there is no RequestBody property.
In this case, RequestText is not truncated as long as you override the
mime type coming from the server, forcing Firefox to pass the data
unaltered. All we need to do is compensate for binary data coming back
and being placed in a Unicode Javascript string. To compensate, we can
AND each character with 0xFF to throw away the high-order byte (see
<https://developer.mozilla.org/En/Using_XMLHttpRequest#Handling_binary_data>).
The resulting encoding function looks like this:  

    Base64 = {
     
     // private property
     _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

     encodeBinary : function(input){
      var output = "";
      var bytebuffer;
      var encodedCharIndexes = new Array(4);
      var inx = 0;
      var paddingBytes = 0;
       
      while(inx < input.length){
       // Fill byte buffer array
       bytebuffer = new Array(3);
       for(jnx = 0; jnx < bytebuffer.length; jnx++)
        if(inx < input.length)
         bytebuffer[jnx] = input.charCodeAt(inx++) & 0xff; // throw away high-order byte, as documented at: https://developer.mozilla.org/En/Using_XMLHttpRequest#Handling_binary_data
        else
         bytebuffer[jnx] = 0;
       
       // Get each encoded character, 6 bits at a time
       // index 1: first 6 bits
       encodedCharIndexes[0] = bytebuffer[0] >> 2;  
       // index 2: second 6 bits (2 least significant bits from input byte 1 + 4 most significant bits from byte 2)
       encodedCharIndexes[1] = ((bytebuffer[0] & 0x3) << 4) | (bytebuffer[1] >> 4);  
       // index 3: third 6 bits (4 least significant bits from input byte 2 + 2 most significant bits from byte 3)
       encodedCharIndexes[2] = ((bytebuffer[1] & 0x0f) << 2) | (bytebuffer[2] >> 6);  
       // index 3: forth 6 bits (6 least significant bits from input byte 3)
       encodedCharIndexes[3] = bytebuffer[2] & 0x3f;  
       
       // Determine whether padding happened, and adjust accordingly
       paddingBytes = inx - (input.length - 1);
       switch(paddingBytes){
        case 2:
         // Set last 2 characters to padding char
         encodedCharIndexes[3] = 64; 
         encodedCharIndexes[2] = 64; 
         break;
        case 1:
         // Set last character to padding char
         encodedCharIndexes[3] = 64; 
         break;
        default:
         break; // No padding - proceed
       }
       // Now we will grab each appropriate character out of our keystring
       // based on our index array and append it to the output string
       for(jnx = 0; jnx < encodedCharIndexes.length; jnx++)
        output += this._keyStr.charAt(encodedCharIndexes[jnx]);
      }
      return output;
     };

  

  
Ideally we'd combine these two functions into a single encoding
function, but I've left them separate for clarity. Note also that these
techniques do not appear to work for Safari, Chrome or Opera. It should
work for IE6 if using the correct ActiveX XHR object, but I was not
supporting IE6. I did a spot check on Safari/Chrome/Opera and they were
not working, but I did not investigate as they were not supported
browsers for my implementation. The actual XHR function I used was:  

    LoadBinaryResource = function(url) { 
      var req = new XMLHttpRequest();  
      req.open('GET', url, false);  

      if (req.overrideMimeType)
        req.overrideMimeType('text/plain; charset=x-user-defined');  
      req.send(null);  
      if (req.status != 200) return '';  
      if (typeof(req.responseBody) !== 'undefined') return BinaryArrayToAscCSV(req.responseBody);
      return req.responseText;  
    } 

    LoadBinaryResourceAsBase64 = function(url) { 
      var data = LoadBinaryResource(url);
      
      if (data.indexOf("BinaryArrayToAscCSV") !== -1)
        return Base64.encodeBinaryArrayAsString(data);
      else
        return Base64.encodeBinary(data);  
    }
