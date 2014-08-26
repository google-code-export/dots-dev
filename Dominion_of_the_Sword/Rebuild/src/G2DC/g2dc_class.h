#ifndef G2DC_CLASS_H
#define G2DC_CLASS_H

#include <iostream>
/*
- testing and error messages
*/
#include <fstream>
/*
- read and write files
*/

using namespace std;

class g2dc
{
    public:
        g2dc(char * inputpath, char * outputpath);
        ~g2dc();
    private:
        //variables and objects
        ifstream infile;
        ofstream outfile;
        ofstream modethree;
        ofstream sortoptions;
        char ch;
        char * sorter;
        char * newsorter;
        int cmpstr;
        int start;
        int currentpos;
        int sorterlen;
        int headerpos;
        int column;
        int columnsno;
        int writemode; //0 "", 1 '', 2 [""],3 count length of column and store in extra column, 4 combines 2 and 3
        int sorting; //toggle for sorting the sets by first column
        int errorno; //tracks current error flag
        //functions
        void processheader(); //read and process the header
        void processcolumn(); //read and process the column and move onto next
        void loadsorter(); //load the contents of the sorter cell in the first column
        void skiparow(); //skip a row or rest of it
        void skiptocolumn(); //skip to currently read column
        void errorhandler(int errorno); //handles errors and error messages
        int comparestring();
        void listsorteroptions();
        void countcolumns(); //counts the number of columns in the header
};

#endif
