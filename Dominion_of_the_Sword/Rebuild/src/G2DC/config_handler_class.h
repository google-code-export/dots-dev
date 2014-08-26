#ifndef CONFIG_HANDLER_CLASS_H
#define CONFIG_HANDLER_CLASS_H

#include <iostream>
/*
- testing and error messages
*/
#include <fstream>
/*
- read and write files
*/

using namespace std;

class conhan
{
    public:
        //functions
        conhan(char* configfile, char delimiter);
        ~conhan();
        void showmear(); //showing the contents of config_ar and strlen_ar for testing
        //variables
        char *** config_ar;
        int rows;
    private:
        //variables and objects of other classes
        int columns;
        int ** strlen_ar;
        int errorno; //tracks current error flag
        char delim;
        char* confile;
        ifstream config_r;
        //functions
        int countrowscolumns(); //counts columns and rows based on delimiter
        void countstrlens(); //counts the length in each cell based on delimiter
        void writestrar(); //write file names to config_ar
        void errorhandler(); //common errors handler
        void eoffix(); //to fix end of file when needed
};

#endif
