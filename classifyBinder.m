clc; 
clear all; 
close all;
[FileName,PathName,FilterIndex] = uigetfile('*.dat','Select the csv file');
file=strcat(PathName,FileName);
fid=fopen(file,'r');
sol=1;
S = textscan(fid,'%s','Delimiter','\n');
S = S{1};
fclose(fid);
% S(~cellfun('isempty',R)); % Removing empty lines
cellDataPoints=S(2);
temp=cell2mat(cellDataPoints);
temp2=strsplit(temp);
idxS = strfind(S, '*');
% idArray=[idxFPT idxVSC idxDS1 idxDS2 idxDS3 idxCS idxDT];
idArray = find(not(cellfun('isempty', idxS)));
keywords=cell(7,1);
for ii=1:numel(idArray)
    keywords{ii}=S(idArray(ii));
end
keysForReadingData={'*FPT';'*VSC';'*DS1';'*DS2';'*DS3';'*CS';'*DT'};
for ii=1:numel(idArray)
    searchingIDs(ii)=idxFind(S,keysForReadingData{ii});
end
invalidIntTemp=[];
list=[];
for ii=[1 2 3 4 6 5 7]
    switch ii
        case 1
            FPT=str2double(S{idArray(ii)+1});
            if FPT>230 %FalshPoint minimum 230
                pfFPT=1;
            else
                sol=0;
                error('Did not satisfy flashpoint temperature requirement')
                break;
            end
        case 2
            VSC=str2double(S{idArray(ii)+1});
            if VSC<3 %FalshPoint Maximum 3
                pfVSC=1;
            else
                sol=0;
                error('Did not satisfy viscosity requirement')
                break;
            end
        case 3
            DS1=cell(numel(idArray(ii)+1:idArray(ii+1)-1),1);%Making a cell array of input dependent size
            index=1;
            for jj=idArray(ii)+1:idArray(ii+1)-1
                if isempty(S{jj})
                    DS1=DS1(1:index-1);
                    break;
                end
                DS1{index}=S{jj};
                index=index+1;
            end
            DS1_vals=zeros(index-1,2);
            index=1;
            pfDS1=[];
            for jj=1:numel(DS1)
                DS1_vals(jj,:)=str2double(strsplit(DS1{index},' '));
                if DS1_vals(index,2)>1 %DS1 minimum 1
                    pfDS1=[pfDS1 DS1_vals(index,1)];
                end
                index=index+1;
            end
            if isempty(pfDS1)
                error('Failed in Dynamic Shear Test');
                break;
            end
        case 4
            DS2=cell(numel(idArray(ii)+1:idArray(ii+1)-1),1);%Making a cell array of input dependent size
            index=1;
            for jj=idArray(ii)+1:idArray(ii+1)-1
                if isempty(S{jj})
                    DS2=DS2(1:index-1);
                    break;
                end
                DS2{index}=S{jj};
                index=index+1;
            end
            DS2_vals=zeros(index-1,2);
            index=1;
            pfDS2=[];
            for jj=1:numel(DS2)
                DS2_vals(jj,:)=str2double(strsplit(DS2{index},' '));
                if DS2_vals(index,2)>2.2 %DS2 minimum 2.2
                    pfDS2=[pfDS2 DS2_vals(index,1)];
                end
                index=index+1;
            end
            commonTemp=intersect(pfDS1,pfDS2);
          case 6
            CS=cell(numel(idArray(ii)+1:idArray(ii+1)-1),1);%Making a cell array of input dependent size
            index=1;
            for jj=idArray(ii)+1:idArray(ii+1)-1
                if isempty(S{jj})
                    CS=CS(1:index-1);
                    break;
                end
                CS{index}=S{jj};
                index=index+1;
            end
            CS_vals=zeros(index-1,3);
            index=1;
            pfCS=[];
            pfCS_false=[];
            for jj=1:numel(CS)
                CS_vals(jj,:)=str2double(strsplit(CS{index},' '));
                if CS_vals(index,2)<300 && CS_vals(index,3)>0.3 %s_max 300 m_min 0.3
                    pfCS=[pfCS CS_vals(index,1)];
                else
                    pfCS_false=[pfCS_false CS_vals(index,1)];
                end
                index=index+1;
            end
            if (~isempty(pfCS_false) && idxFind(S,'*DT')-numel(S)~=0)
                DT_vals=zeros(numel(S)-idxFind(S,'*DT'),2);
                for jj=1:numel(pfCS_false)
                    id=find(CS_vals(:,1)==pfCS_false(jj));%Stored the ids where pfCS is false
                    if CS_vals(id,2)>300 && CS_vals(id,2)<600 && CS_vals(id,3)>0.3
                        %DT checking code will go here
                        index=1;
                        for kk=idxFind(S,'*DT')+1:numel(S);
                            if isempty(S{kk})
                                break;
                            end
                            DT{index}=S{kk};
                            DT_vals(index,:)=str2double(strsplit(DT{index},' '));
                            index=index+1;
                        end
                       ind=[];
                        list(jj)=find(pfCS_false==CS_vals(id,1));
                        if DT_vals(find(DT_vals(:,1)==pfCS_false(jj)),2)>1
                            ind=[ind jj];
                        end
                        index=index+1;
                    end  
                end
                
                pfCS=[pfCS pfCS_false(ind)];
                pfCS_false(ind)=[];
                if (~isempty(list))
                    pfCS_false(list)=[];
                end
            end
            index=1;
            for jj=1:numel(commonTemp)
                for kk=1:numel(pfCS)
                    intermediateTemp(index)=((commonTemp(jj)+pfCS(kk)-10)/2)+4;
                    index=index+1;
                end
            end
            intermediateTemp = unique(intermediateTemp);
            index=1;
            for jj=1:numel(commonTemp)
                for kk=1:numel(pfCS_false)
                    invalidIntTemp(index)=((commonTemp(jj)+pfCS_false(kk)-10)/2)+4;
                    index=index+1;
                end
            end
            if (~isempty(invalidIntTemp))
                for jj=1:numel(invalidIntTemp)
                    intermediateTemp=intermediateTemp(intermediateTemp~=invalidIntTemp(jj));
                end
            end
        case 5
            DS3=cell(numel(idArray(ii)+1:idArray(ii+1)-1),1);
            index=1;
            for jj=idArray(ii)+1:idArray(ii+1)-1
                if isempty(S{jj})
                    DS3=DS3(1:index-1);
                    break;
                end
                DS3{index}=S{jj};
                index=index+1;
            end
            DS3_val=zeros(index-1,2);
            index=1;
            pfDS3=[];
            for jj=1:numel(DS3(:,1))
                DS3_val(jj,:)=str2double(strsplit(DS3{index},' '));
                index=index+1;
            end
            index=1;
            common=intersect(DS3_val(:,1),intermediateTemp);
            pfDS3=[];
            for jj=1:numel(common)
                if DS3_val(find(DS3_val(:,1)==common(jj)),2)<5000 %DS3 Maximum 5000
                    pfDS3=[pfDS3 DS3_val(find(DS3_val(:,1)==common(jj)),1)];
                end
            end
            if isempty(pfDS3)
                intermediateTemp=[];
                for jj=1:numel(commonTemp)
                        %This line needs revision as it only reduces the
                        %temperature only one level
                        intermediateTemp(index)=((commonTemp(jj)+pfCS(1)+6-10)/2)+4;
                        index=index+1;
                end
                for jj=1:numel(intermediateTemp)
                    if DS3_val(find(DS3_val(:,1)==intermediateTemp(jj)),2)<5000
                        pfDS3(jj)=[pfDS3 intermediateTemp(jj)];
                    end
                end    
            end
 
        case 7     
    end
end

if sol~=0
    H=max(commonTemp);
    L=H-(min(pfDS3)-4)*2;
    disp(strcat({'PG'},{' '},num2str(H),{'-'},num2str(L)))
end

