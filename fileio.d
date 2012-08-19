

/* This version of microEmacs is based on the public domain C
 * version written by Dave G. Conroy.
 * The D programming language version is written by Walter Bright.
 * http://www.digitalmars.com/d/
 * This program is in the public domain.
 */

/*
 * The routines in this file read and write ASCII files from the disk. All of
 * the knowledge about files are here. A better message writing scheme should
 * be used.
 */

module fileio;

import std.file;
import std.path;
import std.string;
import std.stdio;
import std.c.stdio;
import std.c.stdlib;
import core.stdc.errno;

version (Windows)
{
    import std.c.windows.windows;
}

version (linux)
{
    import std.c.linux.linux;
}

import ed;
import display;

enum ENOENT = 2;

enum
{
    FIOSUC = 0,                      /* File I/O, success.           */
    FIOFNF = 1,                      /* File I/O, file not found.    */
    FIOEOF = 2,                      /* File I/O, end of file.       */
    FIOERR = 3,                      /* File I/O, error.             */
}

/***************************
 * Determine if file is read-only.
 */

bool ffreadonly(string name)
{
    uint a;
    try
    {
	a = std.file.getAttributes(name);
    }
    catch (Object o)
    {
    }

    version (Win32)
    {
	return (a & FILE_ATTRIBUTE_READONLY) != 0;
    }
    else
    {
	return (a & S_IWRITE) == 0;
    }
}

/*
 * Rename a file
 */
int ffrename(string from, string to)
{
    try
    {
	from = std.path.expandTilde(from);
	to = std.path.expandTilde(to);
	version (linux)
	{
	    struct_stat buf;
	    if( stat( toStringz(from), &buf ) != -1
	     && !(buf.st_uid == getuid() && (buf.st_mode & 0200))
	     && !(buf.st_gid == getgid() && (buf.st_mode & 0020))
	     && !(                          (buf.st_mode & 0002)) )
	    {
		    mlwrite("Cannot open file for writing.");
		    /* Note the above message is a lie, but because this	*/
		    /* routine is only called by the backup file creation	*/
		    /* code, the message will look right to the user.	*/
		    return( FIOERR );
	    }
	}
	rename( from, to );
    }
    catch (Object o)
    {
    }
    return( FIOSUC );
}


/*
 * Change the protection on a file <subject> to match that on file <image>
 */
int ffchmod(string subject, string image)
{
    version (linux)
    {
	subject = std.path.expandTilde(subject);
	image = std.path.expandTilde(image);

	uint attr;
	try
	{
	    attr = std.file.getAttributes(image);
	}
	catch (FileException fe)
	{
		return( FIOSUC );
		/* Note that this won't work in all cases, but because	*/
		/* this is only called from the backup file creator, it	*/
		/* will work.  UGLY!!					*/
	}
	if (chmod( toStringz(subject), attr ) == -1 )
	{
		mlwrite("Cannot open file for writing.");
		/* Note the above message is a lie, but because this	*/
		/* routine is only called by the backup file creation	*/
		/* code, the message will look right to the user.	*/
		return( FIOERR );
	}
    }
    return( FIOSUC );
}
