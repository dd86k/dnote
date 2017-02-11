module dnote;

import std.stdio;
import std.path : dirSeparator, baseName;
import std.file;

const enum { // App constants
    APP_NAME    = "dnote",
    APP_VERSION = "0.1.0",
    FOLDER_NAME = ".dnote",
}

const enum { // CLI Error list
    E_S = 0,        // Success
    // CLI
    E_CLICOM,       // Invalid command
    E_CLICRE,       // Invalid CLI (create)
    E_CLISHO,       // Invalid CLI (create)
    // Operation
    E_CGUP,     // Can't get User Profile
    E_MNC,      // Missing note content
    E_AFM,      // Application folder is missing
    E_AFF,      // Application folder is a file
    E_NDE,      // Note doesn't exist
    E_NAE,      // Note already exist
    E_UCA,      // User canceled action
}

static string dnote_folder;

version (Windows) extern (Windows) {
    import core.sys.windows.windows;
    HRESULT SHGetFolderPathW(
        HWND hwndOwner, int nFolder, HANDLE hToken, DWORD dwFlags, LPWSTR pszPath
    );
}

/*
 * CLI
 */

int main(string[] args)
{
    size_t l = args.length;

    if (l <= 1)
    {
        print_help(args[0]);
        return 0;
    }

    switch (args[1]) // Command
    {
        case "-h", "--help", "/?":
            print_help(args[0]);
            return E_S;
        case "-v", "--version":
            print_version(args[0]);
            return E_S;

        case "h", "help":
            if (l > 2)
                showhelp(args[2]);
            else
                print_help(args[0]);
            return E_S;

        case "c", "create":
            if (l > 2)
                return create(args[2..$]);
            else
                showhelp("create");
            break;
        case "s", "show":
            if (l > 2)
                return show(args[2..$]);
            else
                showhelp("show");
            break;
        case "m", "modify":
            if (l > 2)
                return modify(args[2..$]);
            else
                showhelp("modify");
            break;
        case "l", "ls", "list":
            if (l > 2)
                showhelp("list");
            else
                return list();
            break;
        case "d", "rm", "delete":
            if (l > 2)
                return delete_(args[2..$]);
            else
                showhelp("delete");
            break;
        default:
            writefln(`"%s" is an invalid command.`, args[1]);
            return E_CLICOM;
    }
    
    return 0;
}

void print_help(string app = APP_NAME)
{
    writefln("%s [<Command>] <Arguments>", app);
    writeln("Commands:");
    writeln("  c, create   Create a new note.");
    writeln("  s, show     Show the content of a note.");
    writeln("  m, modify   Modify the content of a note.");
    writeln("  l, list     List existing notes.");
    writeln("  d, delete   Delete an existing notes.\n");
    writeln("Arguments:");
    writeln("  -h, --help, /?   Show the help screen and quits.");
    writeln("  -v, --version    Show the version screen and quits.\n");
    writefln(`To get help on a command, see "%s <Command> --help" or "%s help <Command>".`, app, app);
}

void print_version(string app = APP_NAME)
{
    writefln("%s - v%s", app, APP_VERSION);
    writeln("Copyright (c) 2017 dd86k");
    writeln("License: MIT");
    writeln("Project page: <https://github.com/dd86k/dnote>");
    writefln("Compiled %s on %s with %s v%s",
        __FILE__, __TIMESTAMP__, __VENDOR__, __VERSION__);
}

/*
 * Application
 */

int create(string[] args)
{
    size_t l = args.length;
    switch (args[0])
    {
        case "--help", "/?":
            showhelp("create");
            return E_S;
        default: {
            size_t si = 0; // Starting [slice] index
            bool cname; // List of 
            string name;

            // CLI
            for (size_t i = 0; i < l; ++i)
            {
                switch (args[i])
                {
                    case "-n", "/n":
                        if (++i < l) {
                            debug writeln("-n Name: ", args[i]);
                            name = args[i];
                            cname = true;
                            si += 2;
                        } else {
                            writeln("-n : Missing name.");
                            return E_CLICRE;
                        }
                        break;
                    default:
                }
            }

            if (si >= l)
            {
                writeln("Missing note content.");
                return E_MNC;
            }

            string up = get_userfolder;

            if (up == null)
            {
                writeln("There was an error getting the userfolder.");
                return E_CGUP;
            }

            dnote_folder = get_dnote_folder(up);
            
            if (exists(dnote_folder))
            {
                if (isFile(dnote_folder))
                {
                    writefln("Can't create application folder, %s already exists as a file.",
                        FOLDER_NAME);
                    return E_AFF;
                }
            }
            else
            {
                mkdir(dnote_folder);
            }

            if (cname == false)
            {
                import std.range.primitives, std.format;
                size_t n = dirEntries(dnote_folder, SpanMode.shallow).walkLength!() + 1;
                name = format("%d", n);
                cname = true;
            }

            string fullname = dnote_folder ~ dirSeparator ~ name;

            if (exists(fullname))
            {
                writefln(`Note "%s" already exists.`, name);
                return E_NAE;
            }

            string data = args[si];
            foreach(s; args[si + 1..$])
                data ~= ' ' ~ s;

            std.file.write(fullname, data);
            writefln(`Note created as "%s".`, name);
        }
            break;
    }

    return E_S;
} // create

int show(string[] args)
{
    size_t l = args.length;
    switch (args[0])
    {
        case "--help", "/?":
            showhelp("show");
            return E_S;
        default:
            if (l < 1) // sanity check
            {
                writeln("Missing argument.");
                return E_CLISHO;
            }

            string up = get_userfolder;

            if (up == null)
            {
                writeln("There was an error getting the userfolder.");
                return E_CGUP;
            }

            dnote_folder = get_dnote_folder(up);
            
            if (exists(dnote_folder))
            {
                if (isFile(dnote_folder))
                {
                    writefln("Can't check folder, %s already exists as a file.", FOLDER_NAME);
                    return E_AFF;
                }
            }
            else
            {
                writefln(`%s folder does not exist.`, FOLDER_NAME);
                return E_AFM;
            }
            
            string fullname = dnote_folder ~ dirSeparator ~ args[0];

            if (exists(fullname))
            {
                File f = File(fullname);
                string buf;
                while ((buf = f.readln) !is null)
                    write(buf);
            }
            else
            {
                writefln(`Note "%s" does not exist.`, args[0]);
                return E_NDE;
            }
            break;
    }

    return E_S;
} // show

int modify(string[] args)
{
    size_t l = args.length;
    switch (args[0])
    {
        case "--help", "/?":
            showhelp("modify");
            return E_S;
        default:
            size_t si;
            bool append = false;

            for (size_t i = 0; i < l; ++i)
            {
                switch (args[i])
                {
                    case "-a", "/a":
                        append = true;
                        ++si;
                        break;
                    default:
                }
            }

            if (si + 2 > l)
            {
                writeln("Missing content.");
                return E_MNC;
            }

            string name = args[si];
            string up = get_userfolder;

            if (up == null)
            {
                writeln("There was an error getting the userfolder.");
                return E_CGUP;
            }

            dnote_folder = get_dnote_folder(up);

            if (exists(dnote_folder))
            {
                if (isFile(dnote_folder))
                {
                    writefln("Can't check folder, %s already exists as a file.", FOLDER_NAME);
                    return E_AFF;
                }
            }
            else
            {
                writeln("Note folder doesn't exist, try creating a note first!");
                return E_AFM;
            }

            string fullname = dnote_folder ~ dirSeparator ~ name;

            if (!exists(fullname))
            {
                writefln(`Note "%s" does not exist.`, name);
                return E_NDE;
            }

            string data = args[si + 1];
            foreach(s; args[si + 2..$])
                data ~= ' ' ~ s;

            if (append)
            {
                File f = File(fullname);
                f.write(' ');
                f.write(data);
            }
            else
                std.file.write(fullname, data);
            break;
    }

    return E_S;
} // modify

int list()
{
    string up = get_userfolder;

    if (up == null)
    {
        writeln("There was an error getting the userfolder.");
        return E_CGUP;
    }

    dnote_folder = get_dnote_folder(up);

    if (!exists(dnote_folder))
    {
        writefln(`%s folder does not exist.`, FOLDER_NAME);
        return E_AFM;
    }

    writefln("%-20s %s", "Note", "Content");
    for (int a = 0; a < 2; ++a) {
        for (int i = 0; i < 20; ++i)
            write('-');
        write(' ');
    }
    writeln();

    foreach(e; dirEntries(dnote_folder, SpanMode.shallow)) {
        writef("%-21s", baseName(e.name));
        char[20] buf;
        File f = File(e.name);
        f.rawRead(buf);
        writeln(buf);
    }

    return E_S;
} // list

int delete_(string[] args)
{
    size_t l = args.length;
    switch (args[0])
    {
        case "--help", "/?":
            showhelp("delete");
            return E_S;
        default:
            size_t si;
            bool yes, all;

            for (size_t i = 0; i < l; ++i)
            {
                switch (args[i])
                {
                    case "-y", "/y":
                        yes = true;
                        ++si;
                        break;
                    case "-a", "/a":
                        all = true;
                        break;
                    default:
                }
            }

            string up = get_userfolder;

            if (up == null)
            {
                writeln("There was an error getting the userfolder.");
                return E_CGUP;
            }

            dnote_folder = get_dnote_folder(up);

            if (exists(dnote_folder))
            {
                if (isFile(dnote_folder))
                {
                    writefln("Can't check folder, %s already exists as a file.", FOLDER_NAME);
                    return E_AFF;
                }
            }
            else
            {
                writeln(`Folder "%s" does not exist.`, FOLDER_NAME);
                return E_AFM;
            }

            if (all)
            {
                if (!yes)
                {
                    write("Are you sure to delete every note? [y/n] ");
                    string ln = readln();
                    if (ln.length > 0)
                    {
                        if (ln[0] != 'y')
                        {
                            writeln("Canceled.");
                            return E_UCA;
                        }
                    }
                    else return E_UCA;
                }

                foreach (e; dirEntries(dnote_folder, SpanMode.shallow))
                    remove(e.name);
            }
            else
            {
                string name = args[si];
                string fullname = dnote_folder ~ dirSeparator ~ name;

                if (!exists(fullname))
                {
                    writefln(`Note "%s" does not exist.`, name);
                    return E_NDE;
                }

                if (!yes)
                {
                    writef(`Are you sure to delete "%s"? [y/n] `, name);
                    string ln = readln();
                    if (ln.length > 0)
                    {
                        if (ln[0] != 'y')
                        {
                            writeln("Canceled.");
                            return E_UCA;
                        }
                    }
                    else return E_UCA;
                }

                remove(fullname);
            }
            break;
    }

    return E_S;
} // delete

void showhelp(string command)
{
    switch (command)
    {
        case "c", "create":
            writeln("create [-n <Name>] <Note>");
            writeln("Creates a new note.");
            writeln("  -n   Name the new note.\n");
            writefln("By default, when unamed, names will be determined " ~
                `by the number of existing notes, starting at "1". If the %s folder does ` ~
                `not exist, %s will create it`, FOLDER_NAME, APP_NAME);
            break;
        case "s", "show":
            writeln("show <Name>");
            writeln("Show the content of a note.");
            //writeln();
            //writeln();
            break;
        case "m", "modify":
            writeln("modify <Name> <Note>");
            writeln("Modify the content of a note.");
            writeln("  -a   Append instead of replacing.\n");
            writeln("By default, modify replaces the content of a note.");
            break;
        case "l", "list":
            writeln("list");
            writeln("Lists all notes.");
            //writeln("");
            //writeln("");
            break;
        case "d", "delete":
            writeln("delete [-y] {<Note>|-a}");
            writeln("Delete a note.");
            writeln("  -y   Automatically confirm yes.");
            writeln("  -a   All notes.\n");
            writeln("By default, there will be a confirmation menu for the selected note.");
            break;
        default:
            writefln(`"%s" is not a valid command.`, command);
            break;
    }
}

string get_userfolder()
{
    version (Windows)
    {
        enum folder = 0x28; // CSIDL_PROFILE from
        // http://www.installmate.com/support/im9/using/symbols/functions/csidls.htm
        import core.stdc.wchar_ : wcslen;
        import std.utf : toUTF8;

        wchar[MAX_PATH] buffer;
        wchar* ptr = buffer.ptr;
        if (!SHGetFolderPathW(null, folder, null, 0, ptr)) // Works from XP to 10
            return buffer[0 .. wcslen(ptr)].toUTF8();

        debug writeln("get_userfolder: null");
        return null;
    }
    else version (linux)
    {
        static assert(0, "get_userfolder : Not implemented in Linux.");
        import core.sys.linux.unistd, core.stdc.stdlib;
        /* unistd:
        - getuid()
           stdlib:
        - getenv()
        
        #include <unistd.h>
        #include <sys/types.h>
        #include <pwd.h>

        const char *homedir;

        if ((homedir = getenv("HOME")) == NULL) {
            homedir = getpwuid(getuid())->pw_dir;
        }
        */
    }
    else version (OSX)
    {
        static assert(0, "get_userfolder : Not implemented in OSX.");
    }
    else
        static assert(0, "Target operating system is not supported.");
}

string get_dnote_folder(string userprofile)
{
    return userprofile ~ dirSeparator ~ FOLDER_NAME;
}