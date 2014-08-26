#include <iostream>
/*
- testing and error messages
*/
#include <fstream>
/*
- read and write files
*/

using namespace std;

int main()
{
    ifstream infile;
    infile.open("modeldb_prefinal.txt");

    char ch = NULL;
    int number = 0;
    int finalnumber = 0;

    ofstream outfile;
    outfile.open("merge/modeldb/modeldb.txt", fstream::binary);

    if(infile.is_open())
    {
        ch = infile.peek();

        while(infile.good())
        {
            ch = infile.get();

            while(ch != '*' && infile.good())
            {
                outfile.put(ch);
                ch = infile.get();
            }

            if(infile.good())
            {
                number = 0;
                finalnumber = 0;

                infile >> number;
                finalnumber = finalnumber+number;

                ch = infile.get();

                if(ch == '+')
                {
                    infile >> number;
                    finalnumber = finalnumber+number;
                    ch = infile.get();
                }
                else
                    outfile << finalnumber;

                if(ch == '+')
                {
                    infile >> number;
                    finalnumber = finalnumber+number;
                    ch = infile.get();
                }
                else
                    outfile << finalnumber;

                outfile.put(ch);
            }
        }
    }

    infile.close();
    outfile.close();

    return 0;
}
