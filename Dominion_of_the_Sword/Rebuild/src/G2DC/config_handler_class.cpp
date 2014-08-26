#include "config_handler_class.h"

conhan::conhan(char* configfile, char delimiter)
{
    columns = 1;
    rows = 0;
    config_ar = NULL; //char***
    strlen_ar = NULL; //int**
    delim = delimiter;
    confile = configfile;
    errorno = 0;

    config_r.open(confile);

//Count rows, columns and check the syntax.
    if(config_r.is_open())
        countrowscolumns();
    else
    {
        errorno = 1;
        errorhandler();
    }

    if(errorno == 0)
    {
        //config_ar (3D array of strings).
        config_ar = new char **[rows];

        for(int i=0;i<rows;i++)
            config_ar[i]= new char *[columns];

        //strlen_ar (2D array of integers).
        strlen_ar = new int *[rows];

        for(int i=0;i<rows;i++)
            strlen_ar[i]= new int [columns];

        //Count the string lengths.
        countstrlens();
        //Write the strings to the config_ar.
        writestrar();
        //OPTIONAL. Show the contents of the config_ar and strlen_ar. Disabled by default.
        //showmear();
    }
}

conhan::~conhan()
{
    config_r.close();

//DEALLOCATING IN THE REVERSE ORDER
//strlen_ar
    for(int i=0;i<rows;i++)
        delete [] strlen_ar[i]; //Deallocate columns.

    delete [] strlen_ar; //Deallocate the original array.

//config_ar
    for(int i=0;i<rows;i++)
    {
        for(int j=0;j<columns;j++)
            delete [] config_ar[i][j]; //Deallocate cells.
    }

    for(int i=0;i<rows;i++)
        delete [] config_ar[i]; //Deallocate columns.

    delete [] config_ar; //Deallocate the original array.

    //cout << endl << "Deallocating successful!";
}

int conhan::countrowscolumns()
{
    int ch = NULL;

//COLUMNS
    while(ch != '\n') //Until end of line.
    {
        ch = config_r.get();
        if(ch == delim)
            columns++;
    }

    if(columns == 1)
    {
        errorno = 2;
        errorhandler(); //If there is only one column the syntax is invalid.
        return 1;
    }

    config_r.clear();
    config_r.seekg(0); //Return to the beginning of the file once done.

//ROWS
    int eols = 0;

    while(!config_r.eof()) //Until end of file.
    {
        ch=config_r.get();

        if(ch==delim)
            rows++;
        if(ch=='\n')
            eols++;
    }

    if(rows == (eols+1))
        eoffix(); //If the rows and end of lines does not match call the eoffix function to fix it.
    else
    {
        config_r.clear();
        config_r.seekg(0); //Return to the beginning of the file once done.
    }
    return 0;
}

void conhan::errorhandler()
{
    if(errorno == 1)
        cout << "File not found or inaccessible!";
    else if(errorno == 2)
        cout << "Invalid syntax of the configuration file! Please refer to the readme.";
}

void conhan::eoffix()
{
    config_r.close(); //Close the config for read first...
    ofstream config_w; //...and load config for writing.
    config_w.open(confile,ios_base::app); //Opens the config and sets the stream position to the end.
    config_w.put('\n');
    config_w.close();
    config_r.open(confile); //Open config for read again.
}

void conhan::countstrlens()
{
    int cols = 0; //Tracks the columns.
    char ch = NULL; //Tracks the cahracters in stream.
    int str_len = 0; //Tracks the length of each string.

    for(int i=0;i<rows;i++)
    {
        while(!config_r.eof()) //Until end of file.
        {
            ch = config_r.get();
            str_len++;

            if(ch==delim)
            {
                config_ar[i][cols] = new char[str_len+1]; //Allocate string length in the 2D array + space for \0...
                strlen_ar[i][cols] = str_len; //... and also save the length of the string.

                ch = config_r.peek();
                if(ch==' ')
                    config_r.get(); //Skip next character if there is a whitespace.

                str_len = 0; //Resets string length tracker.

                if(cols<columns-1)
                    cols++; //Increase columns tracker if there is more than two columns.
            }
            else if(ch=='\n')
            {
                cols = columns-1; //Sets the last column.
                config_ar[i][cols] = new char[str_len+1];
                strlen_ar[i][cols] = str_len;
                cols = 0; //Reset the columns tracker...
                str_len = 0; //...and the string length tracker...
                ch = NULL; //...and the character tracker.
                break;
            }
        }
    }

    config_r.clear();
    config_r.seekg(0); //Return to the beginning of the file once done.
}

void conhan::writestrar()
{
    char ch = NULL;
    int j = 0;

    for(int i=0;i<rows;i++)
    {
        for(j=0;j<(columns-1);j++)
        {
            config_r.get(config_ar[i][j],strlen_ar[i][j],delim);
            config_r.get(); //Skip the delimiter.
            ch = config_r.peek();
            if(ch==' ')
                config_r.get(); //Skip yet another character if there is a whitespace.
        }
        config_r.get(config_ar[i][j],strlen_ar[i][j]); //Until end of line (last column)...
        config_r.get(); //...which gets skipped
    }
}

void conhan::showmear()
{
    for(int i = 0;i<rows;i++)
    {
        for(int j = 0;j<columns;j++)
        {
            cout << config_ar[i][j] << " " << strlen_ar[i][j] << endl;
        }
        cout << endl;
    }
}
