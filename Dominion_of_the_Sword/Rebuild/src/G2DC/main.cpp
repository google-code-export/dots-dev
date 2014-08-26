#include <iostream>
/*
- testing and error messages
*/
#include <fstream>
/*
- read and write files
*/
#include <cstring>
/*
- strlen
*/

#include "config_handler_class.h"
#include "g2dc_class.h"

int main()
{
    const char* CFG = "G2DC_config.cfg";
    char* configfile = new char[strlen(CFG)];
    strcpy(configfile,CFG);

    conhan config (configfile,',');
    //config.showmear();

    for(int i=0;i<config.rows;i++)
    {
        g2dc convert (config.config_ar[i][0],config.config_ar[i][1]);
        cout << config.config_ar[i][1] << " is ready!\n";
    }

    delete [] configfile;
    return 0;
}


