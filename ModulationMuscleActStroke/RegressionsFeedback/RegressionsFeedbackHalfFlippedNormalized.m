clear all
close all
clc

%In this version the following has been updated
% - Patient selection has changed according to what we agreed on in Sept 2018
% - Regressions are performed on normalized vectors, since BM on the non-normalized data depends on
%   magnitude in the stroke group (rho=-0.55, p=0.046).
% - We use the first 5 strides to characterize feedback-generated activity
% - The data table for individual subjects will be generated with all 16
%   subjects, such that different selections are possible in subsequent
%   analyses (set allSubFlag to 1)
% - Analyses on group median data are performed with allSubFlag at 0,
%   subject selection depends on speedMatchFlag


[loadName,matDataDir]=uigetfile('*.mat');
loadName=[matDataDir,loadName];
load(loadName)

speedMatchFlag=0;
allSubFlag=0;%Needed to run SubjectSelection script
%this needs to happen separately, since indices will be messed up ohterwise

groupMedianFlag=1; %do not change
nstrides=5;% do not change for early epochs
summethod='nanmedian';% do not change

SubjectSelection% subjectSelection has moved to different script to avoid mistakes accross scripts

pIdx=1:length(strokesNames);
cIdx=1:length(controlsNames);

%define groups
groups{1}=controls.getSubGroup(controlsNames);
groups{2}=patients.getSubGroup(strokesNames);
sNames=strokesNames;
cNames=controlsNames;

%% Get normalized parameters:
%Define parameters we care about:
mOrder={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'HIP', 'ADM', 'TFL', 'GLU'};
%mOrder={'TA','SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF'};
nMusc=length(mOrder);
type='s';
labelPrefix=fliplr([strcat('f',mOrder) strcat('s',mOrder)]); %To display
labelPrefixLong= strcat(labelPrefix,['_' type]); %Actual names

%Renaming normalized parameters, for convenience:
for k=1:length(groups)
    ll=groups{k}.adaptData{1}.data.getLabelsThatMatch('^Norm');
    l2=regexprep(regexprep(ll,'^Norm',''),'_s','s');
    groups{k}=groups{k}.renameParams(ll,l2);
end
newLabelPrefix=fliplr(strcat(labelPrefix,'s'));

eE=1;
eL=1;

ep=defineEpochs({'BASE','eA','lA','eP'},{'TM base','Adaptation','Adaptation','Washout'},[-40 nstrides -40 nstrides],[eE eE eE eE],[eL eL eL eL],summethod);
baseEp=defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],summethod);

%extract data for stroke and controls separately
padWithNaNFlag=false;

[CdataEMG,labels]=groups{1}.getPrefixedEpochData(newLabelPrefix,ep,padWithNaNFlag);
[CBB,labels]=groups{1}.getPrefixedEpochData(newLabelPrefix,baseEp,padWithNaNFlag);
CdataEMG=CdataEMG-CBB; %Removing base

[SdataEMG,labels]=groups{2}.getPrefixedEpochData(newLabelPrefix,ep,padWithNaNFlag);
[SBB,labels]=groups{2}.getPrefixedEpochData(newLabelPrefix,baseEp,padWithNaNFlag);
SdataEMG=SdataEMG-SBB; %Removing base

%replace SOL muscles PT 5 with zeros to minimize effect of loose sensor
labels2=labels(:);
Index = find(contains(labels2,'sSOL'));%find all Soleus muscle data in the labels
ptIdx=find(contains(strokesNames,'P0005'));
SdataEMG(Index,:,ptIdx)=NaN;%I checked this and it indeed removes all the large peaks from the subject data, regardles of which subs are selected
SdataEMG(Index,:,ptIdx)=nanmedian(SdataEMG(Index,:,:),3);

%Flipping EMG:
CdataEMG=reshape(flipEMGdata(reshape(CdataEMG,size(labels,1),size(labels,2),size(CdataEMG,2),size(CdataEMG,3)),1,2),numel(labels),size(CdataEMG,2),size(CdataEMG,3));
SdataEMG=reshape(flipEMGdata(reshape(SdataEMG,size(labels,1),size(labels,2),size(SdataEMG,2),size(SdataEMG,3)),1,2),numel(labels),size(SdataEMG,2),size(SdataEMG,3));

%% Get all the eA, lA, eP vectors
shortNames={'lB','eA','lA','eP'};
longNames={'BASE','eA','lA','eP'};
for i=1:length(shortNames)
    aux=squeeze(CdataEMG(:,strcmp(ep.Properties.ObsNames,longNames{i}),:));
    eval([shortNames{i} '_C=aux;']);
    
    aux=squeeze(SdataEMG(:,strcmp(ep.Properties.ObsNames,longNames{i}),:));
    eval([shortNames{i} '_S=aux;']);
end
clear aux

%compute eAT
eAT_C=fftshift(eA_C,1);
eAT_S=fftshift(eA_S,1);

%% Do group analysis:
rob='off';

    
    if groupMedianFlag
        ttC=table(-median(eA_C(:,cIdx),2), median(eAT_C(:,cIdx),2), -median(lA_C(:,cIdx),2), median(eP_C(:,cIdx),2)-median(lA_C(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
        %patients that are don't have good data will be removed
        ttS=table(-median(eA_S(:,pIdx),2), median(eAT_S(:,pIdx),2), -median(lA_S(:,pIdx),2), median(eP_S(:,pIdx),2)-median(lA_S(:,pIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
    
        ttSFlipped=table(-median(eA_C(:,cIdx),2), median(eAT_C(:,cIdx),2), -median(lA_C(:,cIdx),2), median(eP_S(:,cIdx),2)-median(lA_S(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
        %patients that are don't have good data will be removed
        ttCFlipped=table(-median(eA_S(:,pIdx),2), median(eAT_S(:,pIdx),2), -median(lA_S(:,pIdx),2), median(eP_C(:,pIdx),2)-median(lA_C(:,pIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
    
        ttSHalfFlipped=table(-median(eA_S(:,cIdx),2), median(eAT_C(:,cIdx),2), -median(lA_C(:,cIdx),2), median(eP_S(:,cIdx),2)-median(lA_S(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
        %patients that are don't have good data will be removed
        ttCHalfFlipped=table(-median(eA_C(:,pIdx),2), median(eAT_S(:,pIdx),2), -median(lA_S(:,pIdx),2), median(eP_C(:,pIdx),2)-median(lA_C(:,pIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
    
    else
%         ttC=table(-mean(eA_C(:,cIdx),2), mean(eAT_C(:,cIdx),2), -mean(lA_C(:,cIdx),2), mean(eP_C(:,cIdx),2)-mean(lA_C(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
%         %patients that are don't have good data will be removed
%         ttS=table(-mean(eA_S(:,pIdx),2), mean(eAT_S(:,pIdx),2), -mean(lA_S(:,pIdx),2), mean(eP_S(:,pIdx),2)-mean(lA_S(:,pIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
    end
    
  
   fIds=1:180;
   sIds=181:360;
   
   ttCFast=ttC(fIds,:);
   ttCSlow=ttC(sIds,:); 
   ttSFast=ttS(fIds,:);
   ttSSlow=ttS(sIds,:); 
   
   ttCFlippedFast=ttCFlipped(fIds,:);
   ttCFlippedSlow=ttCFlipped(sIds,:); 
   ttSFlippedFast=ttSFlipped(fIds,:);
   ttSFlippedSlow=ttSFlipped(sIds,:);
   
   ttCHalfFlippedFast=ttCHalfFlipped(fIds,:);
   ttSHalfFlippedFast=ttSHalfFlipped(fIds,:);
   
   ttSHalfFlippedSlow=ttSHalfFlipped(sIds,:);
   
    %normalizing vectors
    ttC.eATnorm=ttC.eAT./norm(ttC.eAT);
    ttC.eP_lAnorm=ttC.eP_lA./norm(ttC.eP_lA);
    ttC.eAnorm=ttC.eA./norm(ttC.eA);
    
    ttS.eATnorm=ttS.eAT./norm(ttS.eAT);
    ttS.eP_lAnorm=ttS.eP_lA./norm(ttS.eP_lA);
    ttS.eAnorm=ttS.eA./norm(ttS.eA);
    
    ttCFlipped.eATnorm=ttCFlipped.eAT./norm(ttCFlipped.eAT);
    ttCFlipped.eP_lAnorm=ttCFlipped.eP_lA./norm(ttCFlipped.eP_lA);
    ttCFlipped.eAnorm=ttCFlipped.eA./norm(ttCFlipped.eA);
    
    ttSFlipped.eATnorm=ttSFlipped.eAT./norm(ttSFlipped.eAT);
    ttSFlipped.eP_lAnorm=ttSFlipped.eP_lA./norm(ttSFlipped.eP_lA);
    ttSFlipped.eAnorm=ttSFlipped.eA./norm(ttSFlipped.eA);
    
    ttCFast.eATnorm=ttCFast.eAT./norm(ttCFast.eAT);
    ttCFast.eP_lAnorm=ttCFast.eP_lA./norm(ttCFast.eP_lA);
    ttCFast.eAnorm=ttCFast.eA./norm(ttCFast.eA);
    
    ttSFast.eATnorm=ttSFast.eAT./norm(ttSFast.eAT);
    ttSFast.eP_lAnorm=ttSFast.eP_lA./norm(ttSFast.eP_lA);
    ttSFast.eAnorm=ttSFast.eA./norm(ttSFast.eA);
    
    ttCFlippedFast.eATnorm=ttCFlippedFast.eAT./norm(ttCFlippedFast.eAT);
    ttCFlippedFast.eP_lAnorm=ttCFlippedFast.eP_lA./norm(ttCFlippedFast.eP_lA);
    ttCFlippedFast.eAnorm=ttCFlippedFast.eA./norm(ttCFlippedFast.eA);
    
    ttSFlippedFast.eATnorm=ttSFlippedFast.eAT./norm(ttSFlippedFast.eAT);
    ttSFlippedFast.eP_lAnorm=ttSFlippedFast.eP_lA./norm(ttSFlippedFast.eP_lA);
    ttSFlippedFast.eAnorm=ttSFlippedFast.eA./norm(ttSFlippedFast.eA);
    
    
    ttCSlow.eATnorm=ttCSlow.eAT./norm(ttCSlow.eAT);
    ttCSlow.eP_lAnorm=ttCSlow.eP_lA./norm(ttCSlow.eP_lA);
    ttCSlow.eAnorm=ttCSlow.eA./norm(ttCSlow.eA);
    
    ttSSlow.eATnorm=ttSSlow.eAT./norm(ttSSlow.eAT);
    ttSSlow.eP_lAnorm=ttSSlow.eP_lA./norm(ttSSlow.eP_lA);
    ttSSlow.eAnorm=ttSSlow.eA./norm(ttSSlow.eA);
    
    ttCFlippedSlow.eATnorm=ttCFlippedSlow.eAT./norm(ttCFlippedSlow.eAT);
    ttCFlippedSlow.eP_lAnorm=ttCFlippedSlow.eP_lA./norm(ttCFlippedSlow.eP_lA);
    ttCFlippedSlow.eAnorm=ttCFlippedSlow.eA./norm(ttCFlippedSlow.eA);
    
    ttSFlippedSlow.eATnorm=ttSFlippedSlow.eAT./norm(ttSFlippedSlow.eAT);
    ttSFlippedSlow.eP_lAnorm=ttSFlippedSlow.eP_lA./norm(ttSFlippedSlow.eP_lA);
    ttSFlippedSlow.eAnorm=ttSFlippedSlow.eA./norm(ttSFlippedSlow.eA);
    
    ttCHalfFlippedFast.eATnorm=ttCHalfFlippedFast.eAT./norm(ttCHalfFlippedFast.eAT);
    ttCHalfFlippedFast.eP_lAnorm=ttCHalfFlippedFast.eP_lA./norm(ttCHalfFlippedFast.eP_lA);
    ttCHalfFlippedFast.eAnorm=ttCHalfFlippedFast.eA./norm(ttCHalfFlippedFast.eA);
    
    ttSHalfFlippedFast.eATnorm=ttSHalfFlippedFast.eAT./norm(ttSHalfFlippedFast.eAT);
    ttSHalfFlippedFast.eP_lAnorm=ttSHalfFlippedFast.eP_lA./norm(ttSHalfFlippedFast.eP_lA);
    ttSHalfFlippedFast.eAnorm=ttSHalfFlippedFast.eA./norm(ttSHalfFlippedFast.eA);
    
    ttCHalfFlipped.eATnorm=ttCHalfFlipped.eAT./norm(ttCHalfFlipped.eAT);
    ttCHalfFlipped.eP_lAnorm=ttCHalfFlipped.eP_lA./norm(ttCHalfFlipped.eP_lA);
    ttCHalfFlipped.eAnorm=ttCHalfFlipped.eA./norm(ttCHalfFlipped.eA);
    
    ttSHalfFlipped.eATnorm=ttSHalfFlipped.eAT./norm(ttSHalfFlipped.eAT);
    ttSHalfFlipped.eP_lAnorm=ttSHalfFlipped.eP_lA./norm(ttSHalfFlipped.eP_lA);
    ttSHalfFlipped.eAnorm=ttSHalfFlipped.eA./norm(ttSHalfFlipped.eA);
    
    ttSHalfFlippedSlow.eATnorm=ttSHalfFlippedSlow.eAT./norm(ttSHalfFlippedSlow.eAT);
    ttSHalfFlippedSlow.eP_lAnorm=ttSHalfFlippedSlow.eP_lA./norm(ttSHalfFlippedSlow.eP_lA);
    ttSHalfFlippedSlow.eAnorm=ttSHalfFlippedSlow.eA./norm(ttSHalfFlippedSlow.eA);
    
    
  
    %For the full group we only do the slow leg and use the control
    %fast leg as a reference. This is because the non-paretic leg's
    %responses are atypical.
    CmodelFit4=fitlm(ttCSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
    SmodelFit4=fitlm(ttSHalfFlippedSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
    
    figure;hold on;aa=CompareElipses(CmodelFit4,SmodelFit4);
    nsub=length(controlsNames);
    emptycol=NaN(2*nsub,1);
    emptycol2=cell(size(emptycol));
    IndRegressions=table(emptycol2,emptycol2,emptycol,emptycol,emptycol,'VariableNames',{'group','sub','BE','BA','FM'});
    load bioData ;
    %% Individual models::
    rob='off'; %These models can't be fit robustly (doesn't converge)
    %First: repeat the model(s) above on each subject:
%     clear CmodelFitAll* ClearnAll* SmodelFitAll* SlearnAll*
%     ClearnAll4=NaN(16,2);
%     SlearnAll4=NaN(16,2);
%     Cr2All2=NaN(16,1);
%     Sr2All2=NaN(16,1);
  
   % 
    for sj=1:nsub
        IndRegressions.group(sj)={'Control'};
        sjcode = cNames(sj);
        IndRegressions.sub(sj)=sjcode;
        dt=table;
        dt.eA=-eA_C(sIds,sj);
        dt.eAT=ttC.eAT(sIds);%I use the same reference for controls as for the stroke
        %dt.eAT=eAT_C(sIds,sj);
        dt.eP_lA=eP_C(sIds,sj)-lA_C(sIds,sj);
        dt.eAnorm=dt.eA./norm(dt.eA);
        dt.eATnorm=dt.eAT./norm(dt.eAT);
        dt.eP_lAnorm=dt.eP_lA./norm(dt.eP_lA);
        
        tmod=fitlm(dt,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM=find(strcmp(tmod.PredictorNames,'eATnorm'),1,'first');
        IdxBS=find(strcmp(tmod.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.BE(sj)=tmod.Coefficients.Estimate(IdxBS);
        IndRegressions.BA(sj)=tmod.Coefficients.Estimate(IdxBM);
        
        clear dt c sjcode tmod IdxBM IdxBS
    end
    
    for sj=1:nsub
        IndRegressions.group(sj+nsub)={'Stroke'};
        sjcode = sNames(sj);
        IndRegressions.sub(sj+nsub)=sjcode;
        dt=table;
        dt.eA=-eA_S(sIds,sj);
        dt.eAT=ttC.eAT(sIds);%ref of controls
        dt.eP_lA=eP_S(sIds,sj)-lA_S(sIds,sj);
        
        dt.eAnorm=dt.eA./norm(dt.eA);
        dt.eATnorm=dt.eAT./norm(dt.eAT);
        dt.eP_lAnorm=dt.eP_lA./norm(dt.eP_lA);
        
        tmod=fitlm(dt,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM=find(strcmp(tmod.PredictorNames,'eATnorm'),1,'first');
        IdxBS=find(strcmp(tmod.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.BE(sj+nsub)=tmod.Coefficients.Estimate(IdxBS);
        IndRegressions.BA(sj+nsub)=tmod.Coefficients.Estimate(IdxBM);
        tempCode=cell2mat(sjcode);
        IndRegressions.FM(sj+nsub)=FM(str2num(tempCode(end-2:end)));
        clear dt c sjcode tmod IdxBM IdxBS tempCode
    end
    
%     %Magnitude analysis
%     eAMagnC=NaN(16,1);
%     ePMagnC=NaN(16,1);
%     eAMagnS=NaN(16,1);
%     ePMagnS=NaN(16,1);
%     ePBMagnC=NaN(16,1);
%     ePBMagnS=NaN(16,1);
%     lAMagnC=NaN(16,1);
%     lAMagnS=NaN(16,1);
%     
%     
%     for i=cIdx%1:size(eA_C,2)
%         eAMagnC(i,1)=norm(eA_C(:,i));
%         ePMagnC(i,1)=norm([eP_C(:,i)-lA_C(:,i)]);
%         ePBMagnC(i,1)=norm(eP_C(:,i));
%         lAMagnC(i,1)=norm(lA_C(:,i));
%     end
%         
%     for i=pIdx%1:size(eA_S,2)
%         eAMagnS(i,1)=norm(eA_S(:,i));
%         ePMagnS(i,1)=norm([eP_S(:,i)-lA_S(:,i)]);
%         ePBMagnS(i,1)=norm(eP_S(:,i));
%         lAMagnS(i,1)=norm(lA_S(:,i));
%     end
%     
%      
%     
%     load([matDataDir,'bioData'])
%     clear ageC ageS;
%     for c=1:length(groups{1}.adaptData)
%         ageC(c,1)=groups{1}.adaptData{c}.getSubjectAgeAtExperimentDate;
%         genderC{c}=groups{1}.adaptData{c}.subData.sex;       
%     end
%     
%     for c=1:length(groups{2}.adaptData)
%         ageS(c,1)=groups{2}.adaptData{c}.getSubjectAgeAtExperimentDate;
%         genderS{c}=groups{2}.adaptData{c}.subData.sex;
%         affSide{c}=groups{2}.adaptData{c}.subData.affectedSide;
%     end
%     
%     %Selection of subjects removed
%     FMselect=FM;
%     velSselect=velsS;
%     velCselect=velsC;
%     
%     tALL=table;
%     %tALL.group=cell(32,1);
%     tALL.aff=cell(32,1);tALL.sens=NaN(32,1);
%     %tALL.group(1:16,1)={'control'};
%     %tALL.group(17:32,1)={'stroke'};
%     %tALL.group=nominal(tALL.group);
%     tALL.speedMatch=speedMatch;
%     tALL.fullGroup=fullGroup;
%     tALL.gender=[genderC';genderS'];
%     tALL.age=[ageC; ageS];
%     tALL.aff(17:32)=affSide';
%     tALL.vel=[velCselect';velSselect'];
%     tALL.FM=[repmat(34,16,1);FMselect'];
%     tALL.BS=[ClearnAll2(:,1);SlearnAll2(:,1)];
%     tALL.BM=[ClearnAll2(:,2);SlearnAll2(:,2)];
%     tALL.R2=[Cr2All2;Sr2All2];
%     tALL.sens(17:32)=[3.61 3.61 2.83 2.83 6.65 3.61 NaN 3.61 6.65 2.83 6.65 4.56 3.61 3.61 3.61 6.65]';
%     tALL.eAMagn=[eAMagnC;eAMagnS];
%     tALL.ePMagn=[ePMagnC;ePMagnS];
%     tALL.ePBMagn=[ePBMagnC;ePBMagnS];
%     tALL.lAMagn=[lAMagnC;lAMagnS];
%     %tALL.cs=[csc;css];
%     %tALL.cm=[cmc;cms];
%     
%     
%     answer = questdlg('Save results to mat file?');
%     switch answer
%         case 'Yes'
%             save([matDataDir,'RegressionResults.mat'],'tALL');
%             disp('matfile saved')
%         case 'No'
%             disp('data not saved')
%     end
%     


%
% figure
% set(gcf,'Color',[1 1 1])
% x=[1,2];
% subplot(2,3,1)
% hold on
% bar(x,[Clearn1a Slearn1a],'FaceColor',[0.5 0.5 0.5])
% errorbar(x,[Clearn1a Slearn1a],[diff(Clearn1aCI)/2 diff(Slearn1aCI)/2],'Color','k','LineWidth',2,'LineStyle','none')
% set(gca,'XLim',[0.5 2.5],'YLim',[0 1],'XTick',[1 2],'XTickLabel',{''},'FontSize',16)
% ylabel('\beta_M group regression')
% title('ADAPTATION OF FEEDBACK RESPONSES')
%
% subplot(2,3,4)
% hold on
% bar(x,nanmean([ClearnAll2 SlearnAll2]),'FaceColor',[0.5 0.5 0.5])
% errorbar(x,nanmean([ClearnAll2 SlearnAll2]),nanstd([ClearnAll2 SlearnAll2])./sqrt(15),'Color','k','LineWidth',2,'LineStyle','none')
% set(gca,'XLim',[0.5 2.5],'YLim',[0 1],'XTick',[1 2],'XTickLabel',{'CONTROL','STROKE'},'FontSize',16)
% ylabel('\beta_M individual regressions')
%
% 
% clear t TStroke TControl
% t=tALL;
% t.group=nominal(t.group);
% TStroke=t(t.group=='stroke',:);
% TControl=t(t.group=='control',:);
% Clearn1aCI
% Slearn1aCI
% 
% [h,p]=ranksum(TControl.cm,TStroke.cm)
% [h,p]=ranksum(TControl.cs,TStroke.cs)


