/****************************************************************************
 * pseb.c - Copyright 2013 Pufeng Du, Ph.D.                                 *
 *                                                                          *
 * This file is part of PseAAC-Builder v2.0.                                *
 * Pseaac-Builder is free software: you can redistribute it and/or modify   *
 * it under the terms of the GNU General Public License as published by     *
 * the Free Software Foundation, either version 3 of the License, or        *
 * (at your option) any later version.                                      *
 *                                                                          *
 * PseAAC-Builder is distributed in the hope that it will be useful,        *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
 * GNU General Public License for more details.                             *
 *                                                                          *
 * You should have received a copy of the GNU General Public License        *
 * along with PseAAC-Builder.  If not, see <http://www.gnu.org/licenses/>.  *
 ****************************************************************************/

#include "pseb.h"

#ifdef __PSEB_DEBUG__
#include <mcheck.h>
#endif

int main(int argc, char *argv[])
{

#ifdef __PSEB_DEBUG__
    mtrace();
#endif

    parameters *x = paraParseCmdLine(argc,argv,0);
    psebMainProcess(x);
    return 0;
}

void psebMainProcess(parameters *p)
{
    pcprop *h = pcpropLoadMemFile();
    pcpropMakeColDefMap();
    pcpropMakeDefaultSelection();

    if (p->queryflag)
    {
        pcpropPrintMemFile(h);
        return;
    }

    decimal **propmat = NULL;
    pcpropSelectByFile(h,p,&propmat);
    p->pcmat=propmat;

    ifTextFile *t = ifLoadTextFile(p->inputfile);
    prseq *ps =faParseFastaInTextFile(t);
    ifUnloadTextFile(t);

    faAddSegment(&ps,p->cntseg);
    //pcpropConvertSequenceToProperties(&ps, propmat);

    pseaac(&ps,p);
    ofWriteAll(&ps,p);

    //CleanUps
    free(p);
    p=NULL;
    faCleanSequences(&ps);
    pcpropCleanUp(&h);
    free(propmat);
    propmat=NULL;
    free(pcpropSelectedNames);
    pcpropSelectedNames=NULL;

}

