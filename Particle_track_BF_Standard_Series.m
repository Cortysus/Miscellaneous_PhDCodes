%This routine executes a single-particle tracking for bright field images
%in which the particle has a doughnut-like appearance. It applies an
%2D autocorrelation filter with a custom filter input by the user and
%paraboloid fitting to get sub-pixel resolution (see AnalyseTrack.m
%documentation for more details).
%It DOESN'T require pre-tracking procedures.
%This version processes serially multiple files.


%Input: select single-particle (s) or double-particle (d) tracking
loop='a';
while (loop ~= 's') && (loop ~= 'd')
    loop=input('Single or double particle mode? [s/d] ','s');
    if loop=='s'
        opmode=0;
    elseif loop=='d'
        opmode=1;
    else
        disp('Incorrect input from user.')
        loop = 'a';
    end
end




%Input: enter mother directory name (it must end with a "\" sign)
folder1='J:\2016_08_16_Javi_sample_2\';

%Input: enter name stamp of the child directories in the series 
folder2='60x_1.20_Si02_FPS1000_1.5um_TweezerNewSample*';

list = dir([folder1,folder2,'*']);
for i=1:length(list)
    folder2=list(i).name;
    disp(folder2);
    stamp=[folder2,'_'];
    img=imread([folder1,folder2,'/',stamp,'000001.tiff']); %Format this if you series doesn't start with 0 or has a different number of digits

    if opmode==0
        [filter{1},r_max]=CreateFilter(img);
    elseif opmode==1
        [filter{1},r_max,searchSize]=CreateFilterDouble(img);
    else
        error('Error.');
    end
    
    listlen = length(dir([folder1,folder2,'/','*.tiff']));
    
    %Input: by default, the program process all the pictures. Modify the 2nd
    %and 3rd field if necessary
    if opmode==0
        poslist=AnalyseTrack([folder1,folder2,'/',stamp],1,listlen-1,filter,r_max*2,10); %The listlen-1 accounts for one frame being 00000
    elseif opmode==1
        poslist=AnalyseTrackDouble([folder1,folder2,'/',stamp],1,listlen-1,filter,searchSize,r_max*2); %The listlen-1 accounts for one frame being 00000
    else
        error('Error.');
    end
    
    
    %Input: by default, the program will create an output file in the mother
    %directory. Modify if necessary
    fullFileName=fullfile(folder1,['track_particle_output',folder2,'.csv']);
    if exist(fullFileName,'file')==2
        %Input to specify how to deal with pre-existing file
        loop='A';
        while (loop ~= 'Y') && (loop ~= 'N')
            loop=input('Output track file already exists. Do you want to overwrite it? [Y/N] ','s');
            if loop=='Y'
                delete(fullFileName);
            elseif loop=='N'
                while exist(fullFileName,'file')==2
                    fullFileName = [fullFileName(1:end-4),'bis.csv'];
                end
            else
                disp('Incorrect input from user.')
                loop = 'A';
            end
        end
    end
    dlmwrite(fullFileName, poslist, 'delimiter', ',', 'precision', 9); 
    if opmode==0
        figure(2)
        plot(poslist(:,1),poslist(:,2))
        hold on
        plot(poslist(:,1),poslist(:,3))
        hold off
        title(['Coordinates over time, series ',num2str(i)])
        xlabel('Time step')
        ylabel('Pixel')
        legend('X coordinate','Y coordinate')
    end
end
