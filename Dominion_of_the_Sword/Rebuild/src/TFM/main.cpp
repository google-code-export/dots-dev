#include <iostream>
#include<fstream>
#include <string>
#include <sstream>
#include <cstdio>
#include <cstdlib>

#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <vector>

using namespace std;
#include <windows.h>

int getdir (string dir, vector<string> &files);
void TFM(char FILEname[],char OUTPUTname[]);

int main()//(int argc, char *argv[])
{
    /*
    if(argc!=3)
    {
        cout << "Not enough parameters.";
        return 1;
    }
    char INPUTfiles[100][200];
    char OUTPUTfiles[200];

    int i=0;

    while(argv[2][i]!='\0')
    {
        OUTPUTfiles[i]=argv[2][i];
        i++;
    }
    OUTPUTfiles[i]='\0';


    string dir = string("./");
    dir.append(argv[1]);
    cout<<dir<<endl;
    vector<string> files = vector<string>();

    getdir(dir,files);
    int No_files=0;

    for (unsigned int j = 0;j < files.size();j++)
    {
        int k=0;
        while(files[j][k]!='\0')
        {
            INPUTfiles[j][k]=files[j][k];
            k++;
        }
        No_files++;

     //   cout << files[j] << endl;
    }
*/


    char INPUTfiles[100][50][200];
    char OUTPUTfiles[100][200];
    int No_files[100];

    FILE* config;
    config=fopen("TFM_config.cfg","r");

    int No_dir=0;

    while(!feof(config))
    {
        char ch;
        char name[200];
        fscanf(config,"%c",&ch);
        int i=0;
        while(ch!=':')
        {
            name[i]=ch;
            fscanf(config,"%c",&ch);
            i++;
        }
        name[i]='\0';
        strcpy(OUTPUTfiles[No_dir],name);
 //       cout << name << endl;

        fscanf(config,"%c",&ch);
        fscanf(config,"%c",&ch);
        i=0;
        No_files[No_dir]=0;

        while(ch!='\n' && !feof(config))
        {
            i=0;
            while(ch!=',' && ch!='\n' && !feof(config))
                {
                    name[i]=ch;

                    fscanf(config,"%c",&ch);
                    i++;
                }
            if(ch!='\n' && !feof(config))
            {
                fscanf(config,"%c",&ch);
                fscanf(config,"%c",&ch);
            }

            name[i]='\0';
            strcpy(INPUTfiles[No_dir][No_files[No_dir]],name);
            No_files[No_dir]++;
//            cout << No_files[No_dir] << INPUTfiles[No_dir][No_files[No_dir]-1] << endl;
        }
        No_dir++;



    }
    fclose(config);

    for(int i=0;i<No_dir;i++)
    {
        FILE *outputFile;
        outputFile=fopen(OUTPUTfiles[i],"w");
        fclose(outputFile);

        for(int j=0;j<No_files[i];j++)
        {
            TFM(INPUTfiles[i][j],OUTPUTfiles[i]);
        }
        cout << OUTPUTfiles[i] << " is ready!"<<endl;
    }

/*
    FILE *outputFile;
    outputFile=fopen(OUTPUTfiles,"w");
    fclose(outputFile);

    for(int j=0;j<No_files;j++)
    {
        TFM(INPUTfiles[j],OUTPUTfiles);
    }
    cout << OUTPUTfiles << " is ready!"<<endl;
//    char ch;
//    cout << "Press any key: ";
//    cin >> ch;*/

    return 0;
}

void TFM(char FILEname[],char OUTPUTname[])
{
        FILE* myReadFiles,*outputFile;

    outputFile=fopen(OUTPUTname,"a");

    char ch;

    myReadFiles=fopen(FILEname,"r");
    fscanf(myReadFiles,"%c",&ch);

    while(!feof(myReadFiles))
        {
                fprintf(outputFile,"%c",ch);
                fscanf(myReadFiles,"%c",&ch);
        }
    fprintf(outputFile,"\n");
    fclose(myReadFiles);
    fclose(outputFile);
}

int getdir (string dir, vector<string> &files)
{
    DIR *dp;
    struct dirent *dirp;
    if((dp  = opendir(dir.c_str())) == NULL) {
        cout << "Error(" << errno << ") opening " << dir << endl;
        return errno;
    }

    while ((dirp = readdir(dp)) != NULL) {
        files.push_back(string(dirp->d_name));
    }
    closedir(dp);
    return 0;
}
