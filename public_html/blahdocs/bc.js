/**********************************************************
 * BC - "Blah Code" script                                *
 * Copyright © 2001-2006 E-Blah.                          *
 * Part of the E-Blah Software.  Released under the GPL.  *
 *                           Last Update: 9 October, 2006 *
 **********************************************************/

function useAE(file) {
	tinyMCE.execCommand('mceInsertContent', false, tinyMCE.activeEditor.dom.createHTML('img', {
		src : file,
		border : 0,
		align : 'middle'
	}));
}

function use(u,c)
{
    if (!u) u= '';
    if (!c) c= '';
    var bb_obj= document.forms['post'].message; /*document.getElementById('message');*/
    bb_obj.focus();
    if (typeof document.selection!= 'undefined')
    {
        var r= document.selection.createRange();
        var iT= r.text;
        r.text= u+ iT+ c;
        if (iT.length!= 0) r.moveStart('character', bb_obj, iT.length);
        r.select();
    }
    else if (bb_obj.selectionStart || bb_obj.selectionStart == '0')
    {
        var ia= bb_obj.selectionStart, iz= bb_obj.selectionEnd;
        var iT= bb_obj.value.substring(ia, iz);
        bb_obj.value= bb_obj.value.substr(0,ia)+ u+ iT+ c+ bb_obj.value.substr(iz);
        var p= ia+ u.length+ iT.length+ c.length;
        bb_obj.focus();
        bb_obj.selectionStart= p;
        bb_obj.selectionEnd= p;
        bb_obj.focus();
    }
    else
    {
        bb_obj.value += u+c;
        bb_obj.focus();
    }
}
function openuse(u)
{
    var bbo_obj = opener.document.forms['post'].message;
    bbo_obj.value += u;
}
function AddNewValue(bc,thenewvalue)
{
    if(bc != '' && thenewvalue != '')
    {
        use("["+bc+"="+thenewvalue+"]","[/"+bc+"]");
        document.forms['post'].size.value = '';
        document.forms['post'].color.value = '';
        document.forms['post'].face.value = '';
    }
}
function funclu (lookup)
{
    document.getElementById('about').innerHTML = eval('func_'+lookup);
}
