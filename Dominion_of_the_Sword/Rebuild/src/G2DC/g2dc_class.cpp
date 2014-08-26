#include "g2dc_class.h"

g2dc::g2dc(char * inputpath, char * outputpath)
{
    ch = inputpath[0]; //checks first letter of input file name if it needs to be done twice
    start = 0;
    currentpos = 0;
    headerpos = 0;
    column = 1;
    columnsno = 1;
    writemode = 0;
    sorting = 0;
    sorterlen = 0;
    cmpstr = 0;
    sorter = NULL;
    newsorter = NULL;

    if(ch == '&')
    {
        for(int i = 0; inputpath[i] != '\0'; i++)
            inputpath[i] = inputpath[i+1];

        sorting = 1;

        infile.open(inputpath);
    }
    else
        infile.open(inputpath);

    outfile.open(outputpath, fstream::binary);
    modethree.open("mode3.txt", fstream::binary);

    if(infile.is_open())
    {
        skiparow(); //skip the first row
        start = infile.tellg(); //save beginning off file
        countcolumns(); //count the columns in the header

        //processes one column per cycle
        while(infile.good())
        {
            if(sorting == 1 && cmpstr == 0)
            {
                listsorteroptions();
                column++;
                cmpstr++;
            }

            processheader(); //process the header
            processcolumn(); //read the column cell by cell

            if(column <= columnsno)
            {
                infile.clear(); //clears any potential end of file flags
                infile.seekg(start); //get back to the beginning
            }
            else
            {
                if(sorting == 1)
                {
                    infile.clear();
                    infile.seekg(start);
                    sorting = 0;
                    column = 2;
                    writemode = 0;
                }
                else
                    break; //break if the last column has been processed
            }
        }
    }
    else
        errorhandler(1);
}

g2dc::~g2dc()
{
    infile.close();
    modethree.close();

    ifstream m3("mode3.txt");

    if(m3.is_open())
    {
        ch = m3.get();

        while(m3.good()) //joins the mode3 output with the rest
        {
            outfile.put(ch);
            ch = m3.get();
        }
    }

    m3.close();
    outfile.close();
    remove("mode3.txt");

    if(sorter != NULL)
        delete [] sorter;

    if(newsorter != NULL)
        delete [] newsorter;
}

void g2dc::listsorteroptions()
{
    ch = infile.get();

    while(ch != '\t' && ch != '\n' && infile.good())
    {
        outfile.put(ch);
        ch = infile.get();
    }

    outfile.put(':').put(' ').put('[').put('\n');
    skiparow();

    while(infile.good())
    {
        if(ch != '\t' && ch != '\n' && infile.good())
        {
            loadsorter();

            int test = comparestring();

            if(test > 0)
            {
                if(test != 2)
                    outfile.put(',').put('\n');

                outfile.put('\"');
                outfile << sorter;
                outfile.put('\"');
                skiparow();
            }
            else
                skiparow();
        }
    }

    outfile.put('\n').put(']').put('\n').put('\n'); //writes no comma and empty row if the column ends

    infile.clear();
    infile.seekg(start);
}

void g2dc::errorhandler(int errorno)
{
    if(errorno == 1)
        cout << "Input file not found.";
    else
        cout << "Unspecified error.";
}

void g2dc::processheader()
{
    infile.seekg(start);

    if(sorting == 1 && cmpstr == 1)
    {
        skiptocolumn();
        headerpos = infile.tellg();
        skiparow();
        loadsorter();
        outfile << sorter << '_';
        infile.seekg(headerpos); //get back to current position
    }

    else
        skiptocolumn(); //skip to the current column (defaults at 1 which does not skip anywhere)

    ch = infile.peek();

    while(ch != '\t' && ch != '\n' && infile.good())
    {
        ch = infile.get();

        //set the writemode according to the first character in the header else parse the character
        if(ch == '!')
        {
            if(sorting == 1)
                modethree << sorter << '_';

            writemode = 3;
        }
        else if(ch == '#')
            writemode = 2;
        else if(ch == '@')
            writemode = 1;
        else if(ch == '%')
        {
            if(sorting == 1)
                modethree << sorter << '_';

            writemode = 4;
        }
        else if(ch != '\t' && ch != '\n')
        {
            if(writemode == 3 || writemode == 4)
            {
                if(ch != '%' || '#')
                    modethree.put(ch);
            }
                outfile.put(ch);
        }
    }

    outfile.put(':').put(' ').put('[').put('\n');

    if(writemode == 3 || writemode == 4)
        modethree.put('_').put('l').put('e').put('n').put(':').put(' ').put('[').put('\n');

    skiparow(); //skip rest of the header
    skiptocolumn(); //skip to current column to actual column content
}

void g2dc::processcolumn()
{
    while(ch != '\t' && ch != '\n' && infile.good()) //until what is next is end of line or tab
    {
        //write enclosing char(s) based on writemode
        if(writemode == 0)
            outfile.put('\"');
        else if(writemode == 1)
            outfile.put('\'');
        else if(writemode == 2)
            outfile.put('[').put('\'');
        else if(writemode == 3)
        {
            outfile.put('\"');
            modethree.put('\"');
        }
        else if(writemode == 4)
        {
            outfile.put('[').put('\'');
            modethree.put('[').put('\'');
        }

        int length = 0; //for counting the size of the string in the cell
        ch = infile.get(); //read next character in the cell

        //read entire cell
        while(ch != '\t' && ch != '\n' && infile.good())
        {
            if(writemode == 1 && ch == '\'')
                outfile.put(ch).put(ch);
            else if(writemode == 2 && ch == ',')
            {
                outfile.put('\'').put(ch);
                ch = infile.peek();

                if(ch == ' ')
                    ch = infile.get();

                outfile.put(ch).put('\'');
            }
            else if(writemode == 2 && ch == '\'')
                outfile.put(ch).put(ch);
            else if(writemode == 4 && ch == ',')
            {
                modethree << length;
                outfile.put('\'').put(ch);
                modethree.put('\'').put(ch);
                ch = infile.peek();

                if(ch == ' ')
                    ch = infile.get();

                outfile.put(ch).put('\'');
                modethree.put(ch).put('\'');
                length = 0;
            }
            else
            {
                outfile.put(ch);

                if(writemode == 3 || writemode == 4)
                    length++;
            }

            ch = infile.get();
        }

        //write closing char(s) based on writemode
        if(writemode == 0)
            outfile.put('\"');
        else if(writemode == 1)
            outfile.put('\'');
        else if(writemode == 2)
            outfile.put('\'').put(']');
        else if(writemode == 3)
        {
            outfile.put('\"');
            modethree << length;
            modethree.put('\"');
        }
        else if(writemode == 4)
        {
            outfile.put('\'').put(']');
            modethree << length;
            modethree.put('\'').put(']');
        }

        skiparow(); //skip the rest of the row

        cmpstr = 0;

        if(sorting == 1) //sorter check
        {
            currentpos = infile.tellg(); //save current position
            loadsorter();

            cmpstr = comparestring(); //compare old sorter to new one

            if(cmpstr == 1) //if new and old sorters don't match
            {
                outfile.put('\n').put(']').put('\n').put('\n'); //end of previous sorted set

                if(writemode == 3 || writemode == 4)
                    modethree.put('\n').put(']').put('\n').put('\n'); //end of previous sorted set

                outfile << sorter << '_'; //new sorter prepped for new segment of the set
                cmpstr = 0; //make sure processheader is not consdiering this as new column's header
                processheader();
                cmpstr = 1; //reset this so processheader works normally
            }
            infile.seekg(currentpos);
        }

        skiptocolumn(); //skip to the current column in the next row (peeks at next character)

        if(ch != '\t' && ch != '\n' && infile.good())
        {
            if(cmpstr == 0)
                outfile.put(',').put('\n'); //write comma and end of line if there is more data

            if(cmpstr == 0 &&  (writemode == 3 || writemode == 4))
                modethree.put(',').put('\n'); //write comma and end of line if there is more data
        }
    }

    outfile.put('\n').put(']').put('\n').put('\n'); //writes no comma and empty row if the column ends

    if(writemode == 3 || writemode == 4)
        modethree.put('\n').put(']').put('\n').put('\n');

    cmpstr = 1; //reset comparestring counter
    column++;
    writemode = 0; //resets the writemode to 0
}

int g2dc::comparestring()
{
    if(newsorter != NULL && sorter != NULL)
    {
        for(int i = 0;i < sorterlen;i++)
        {
            if(sorter[i] == newsorter[i])
                ;
            else
                return 1;
        }
    }
    else
    {
        return 2;
    }

    return 0;
}

void g2dc::loadsorter()
{
    if(sorter != NULL) //save the old sorter and deallocate it before if needed and then deallocate new sorter space
    {
        if(newsorter != NULL)
            delete [] newsorter;

        newsorter = new char[sorterlen];

        for(int i = 0;i < sorterlen;i++) //assign old sorter to newsorter
        {
            newsorter[i] = sorter[i];
        }

        delete [] sorter;
        sorterlen = 0; //reset sorter length
    }

    int sorterpos = infile.tellg(); //remember the position where the sorterstarted
    ch = infile.peek();


    while(ch != '\t' && ch != '\n' && infile.good()) //count the sorter length
    {
        ch = infile.get();
        sorterlen++;
    }

    sorter = new char[sorterlen]; //allocate space for the sorter (exact number because \t was accounter for and will be replaced with \0)
    infile.seekg(sorterpos); //return cursor to start of sorter

    for(int i = 0;i < sorterlen-1;i++) //read and store the sorter (-1 because of \t being accounted for in the count)
    {
        sorter[i] = infile.get();;
    }

    sorter[sorterlen-1] = '\0';
}

void g2dc::skiparow()
{
    while(ch != '\n' && infile.good())
        ch = infile.get();

    ch = infile.peek(); //and peek to next character again so end of line does not get stuck in ch
}

void g2dc::skiptocolumn()
{
    int i = 1;
    ch = infile.peek();

    while(i < column && infile.good() && ch != '\n')
    {
        ch = infile.get();

        if(ch == '\t')
            i++;
    }

    ch = infile.peek(); //look at next character to be read
}

void g2dc::countcolumns()
{
    while(ch != '\n' && infile.good())
    {
        ch = infile.get();

        if(ch == '\t')
            columnsno++;
    }

    //get back to the beginning
    infile.clear();
    infile.seekg(start);
}
