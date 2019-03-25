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

speedMatchFlag=1;
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

ep=defineEpochs({'BASE','eA','lA','eP','eB','lS'},{'TM base','Adaptation','Adaptation','Washout','TM base','short exposure'},[-40 nstrides -40 nstrides nstrides -8],[eE eE eE eE eE eE],[eL eL eL eL eL eL],summethod);
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

%% Get all the eA, lA, eP vectors, note that eB is right after short exposure
shortNames={'lB','eA','lA','eP','eB','lS'};
longNames={'BASE','eA','lA','eP','eB','lS'};
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
        
        eP_lA_C=eP_C-lA_C;
        eB_lS_C=eB_C-lS_C;
        
        eP_lA_S=eP_S-lA_S;
        eB_lS_S=eB_S-lS_S;
        
        %controls are always their own reference
        ttC=table(-nanmedian(eA_C(:,cIdx),2), nanmedian(eAT_C(:,cIdx),2), -nanmedian(lA_C(:,cIdx),2), nanmedian(eP_lA_C(:,cIdx),2),nanmedian(eB_lS_C(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA','eB_lS'});
        
        %stroke with themselves as a reference
        ttS=table(-nanmedian(eA_S(:,cIdx),2), nanmedian(eAT_S(:,cIdx),2), -nanmedian(lA_S(:,cIdx),2), nanmedian(eP_lA_S(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
       
        %stroke with control reference for eAT
        ttSHalfFlipped=table(-nanmedian(eA_S(:,cIdx),2), nanmedian(eAT_C(:,cIdx),2), -nanmedian(lA_S(:,cIdx),2), nanmedian(eP_lA_S(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
        
        
        %this is to account for the fact that pt 11 did not perform the
        %short exposure
        shIdx=find(~isnan(lS_S(1,:)));
        ttSShort=table(-nanmedian(eA_S(:,shIdx),2), nanmedian(eAT_S(:,cIdx),2), -nanmedian(lA_S(:,shIdx),2), nanmedian(eB_lS_S(:,shIdx),2),'VariableNames',{'eA','eAT','lA','eB_lS'});
        
        ttSHalfFlippedShort=table(-nanmedian(eA_S(:,shIdx),2), nanmedian(eAT_C(:,cIdx),2), -nanmedian(lA_S(:,shIdx),2), nanmedian(eB_lS_S(:,shIdx),2),'VariableNames',{'eA','eAT','lA','eB_lS'});
        
        %ttSHalFFlippedShort=
    else
%         ttC=table(-mean(eA_C(:,cIdx),2), mean(eAT_C(:,cIdx),2), -mean(lA_C(:,cIdx),2), mean(eP_C(:,cIdx),2)-mean(lA_C(:,cIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
%         %patients that are don't have good data will be removed
%         ttS=table(-mean(eA_S(:,pIdx),2), mean(eAT_S(:,pIdx),2), -mean(lA_S(:,pIdx),2), mean(eP_S(:,pIdx),2)-mean(lA_S(:,pIdx),2),'VariableNames',{'eA','eAT','lA','eP_lA'});
    end
    
  
   fIds=1:180;
   sIds=181:360;
   
  %create vectors for single leg
   ttCSlow=ttC(sIds,:);  
   ttSSlow=ttS(sIds,:);
   ttSHalfFlippedSlow=ttSHalfFlipped(sIds,:);
   ttSShortSlow=ttSShort(sIds,:);
   ttSHalfFlippedSlowShort=ttSHalfFlippedShort(sIds,:);%subject 11 did not do short exposure, so this subject was not included
   
   ttCFast=ttC(fIds,:);
   ttSFast=ttS(fIds,:);
   ttSHalfFlippedFast=ttSHalfFlipped(fIds,:);
   ttSShortFast=ttSShort(fIds,:);
   ttSHalfFlippedFastShort=ttSHalfFlippedShort(fIds,:);
    
   %normalizing vectors
   ttCSlow=fcnNormTable(ttCSlow);
   ttSSlow=fcnNormTable(ttSSlow);
   ttSHalfFlippedSlow=fcnNormTable(ttSHalfFlippedSlow);
   ttSShortSlow=fcnNormTable(ttSShortSlow);
   ttSHalfFlippedSlowShort=fcnNormTable(ttSHalfFlippedSlowShort);
   
   ttCFast=fcnNormTable(ttCFast);
   ttSFast=fcnNormTable(ttSFast);
   ttSHalfFlippedFast=fcnNormTable(ttSHalfFlippedFast);
   ttSShortFast=fcnNormTable(ttSShortFast);
   ttSHalfFlippedFastShort=fcnNormTable(ttSHalfFlippedFastShort);
   
   
   
  
    %For the full group we only do the slow leg and use the control
    %fast leg as a reference. This is because the non-paretic leg's
    %responses are atypical.
    
    %Control models
    Cmodel1aSlow=fitlm(ttCSlow,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Cmodel1bSlow=fitlm(ttCSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    Cmodel1aFast=fitlm(ttCFast,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Cmodel1bFast=fitlm(ttCFast,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    %Stroke with own ref
    Smodel1aSlow=fitlm(ttSShortSlow,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Smodel1bSlow=fitlm(ttSSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    Smodel1aFast=fitlm(ttSShortFast,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Smodel1bFast=fitlm(ttSFast,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    %Stroke with control ref
    Smodel1aSlowFl=fitlm(ttSHalfFlippedSlowShort,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Smodel1bSlowFl=fitlm(ttSHalfFlippedSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    Smodel1aFastFl=fitlm(ttSHalfFlippedFastShort,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);%short exposure
    Smodel1bFastFl=fitlm(ttSHalfFlippedFast,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);%long exposure 
    
    
%     CmodelFit4=fitlm(ttCSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
%     SmodelFit4=fitlm(ttSHalfFlippedSlow,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
%     CmodelFit2=fitlm(ttCSlow,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);
%     SmodelFit2=fitlm(ttSHalfFlippedSlowShort,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);
%     ClongR2=uncenteredRsquared(CmodelFit4);ClongR2=ClongR2.uncentered
%     SlongR2=uncenteredRsquared(SmodelFit4);SlongR2=SlongR2.uncentered
%     CshortR2=uncenteredRsquared(CmodelFit2);CshortR2=CshortR2.uncentered
%     SshortR2=uncenteredRsquared(SmodelFit2);SshortR2=SshortR2.uncentered
%     
    
    
    figure;fullscreen;set(gcf,'Color',[1 1 1]);
    
    subplot(2,2,1);hold on;
    aa=CompareElipses(Cmodel1aSlow,Smodel1aSlow);aa=CompareElipses(Cmodel1bSlow,Smodel1bSlow);
    set(gca,'XLim',[0 1],'YLim',[0 1]);%slow leg each group with own ref
    title('Slow Own Ref')
    grid on
    
    subplot(2,2,2);hold on;
    aa=CompareElipses(Cmodel1aSlow,Smodel1aSlowFl);aa=CompareElipses(Cmodel1bSlow,Smodel1bSlowFl);
    set(gca,'XLim',[0 1],'YLim',[0 1]);
    title('Slow Control eAT')
    grid on
    
    subplot(2,2,3);hold on;
    aa=CompareElipses(Cmodel1aFast,Smodel1aFast);aa=CompareElipses(Cmodel1bFast,Smodel1bFast);
    set(gca,'XLim',[0 1],'YLim',[0 1]);%slow leg each group with own ref
    title('Fast Own Ref')
    grid on
    
    subplot(2,2,4);hold on;
    aa=CompareElipses(Cmodel1aFast,Smodel1aFastFl);aa=CompareElipses(Cmodel1bFast,Smodel1bFastFl);
    set(gca,'XLim',[0 1],'YLim',[0 1]);
    title('Fast Control eAT')
    grid on
    
     
    
    nsub=length(controlsNames);
    emptycol=NaN(2*nsub,1);
    emptycol2=cell(size(emptycol));
    IndRegressions=table(emptycol2,emptycol2,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,emptycol,'VariableNames',{'group','sub','BE','BA','FM','sBE','sBA','longR2','shortR2','pBE','pBA','short_pBE','short_pBA','longCI','shortCI','pLong','pShort','vel'});
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
        dt.eB_lS=eB_lS_C(sIds,sj);
        dt.eAnorm=dt.eA./norm(dt.eA);
        dt.eATnorm=dt.eAT./norm(dt.eAT);
        dt.eP_lAnorm=dt.eP_lA./norm(dt.eP_lA);
        dt.eB_lSnorm=dt.eB_lS./norm(dt.eB_lS);
        
        tmod=fitlm(dt,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM=find(strcmp(tmod.PredictorNames,'eATnorm'),1,'first');
        IdxBS=find(strcmp(tmod.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.BE(sj)=tmod.Coefficients.Estimate(IdxBS);
        IndRegressions.BA(sj)=tmod.Coefficients.Estimate(IdxBM);
        R2=uncenteredRsquared(tmod);IndRegressions.longR2(sj)=R2.uncentered;
        IndRegressions.pBE(sj)=tmod.Coefficients.pValue(IdxBS);
        IndRegressions.pBA(sj)=tmod.Coefficients.pValue(IdxBM);
        longCI=tmod.coefCI;
        IndRegressions.longCI(sj)=diff(longCI(1,:))/2;
        [IndRegressions.pLong(sj),dummy]=coefTest(tmod);
    
        
        tmod2=fitlm(dt,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM2=find(strcmp(tmod2.PredictorNames,'eATnorm'),1,'first');
        IdxBS2=find(strcmp(tmod2.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.sBE(sj)=tmod2.Coefficients.Estimate(IdxBS2);
        IndRegressions.sBA(sj)=tmod2.Coefficients.Estimate(IdxBM2);
        R2=uncenteredRsquared(tmod2);IndRegressions.shortR2(sj)=R2.uncentered;
        IndRegressions.short_pBE(sj)=tmod2.Coefficients.pValue(IdxBS);
        IndRegressions.short_pBA(sj)=tmod2.Coefficients.pValue(IdxBM);
        shortCI=tmod2.coefCI;
        IndRegressions.shortCI(sj)=diff(shortCI(1,:))/2;
         [IndRegressions.pShort(sj),dummy]=coefTest(tmod2);
    
        
        clear dt c sjcode tmod IdxBM IdxBS tmod2 IdxBM2 IdxBS2 
    end
    
    for sj=1:nsub
        IndRegressions.group(sj+nsub)={'Stroke'};
        sjcode = sNames(sj);
        IndRegressions.sub(sj+nsub)=sjcode;
        dt=table;
        dt.eA=-eA_S(sIds,sj);
        dt.eAT=ttC.eAT(sIds);%ref of controls
        dt.eP_lA=eP_S(sIds,sj)-lA_S(sIds,sj);
        dt.eB_lS=eB_lS_S(sIds,sj);
        dt.eAnorm=dt.eA./norm(dt.eA);
        dt.eATnorm=dt.eAT./norm(dt.eAT);
        dt.eP_lAnorm=dt.eP_lA./norm(dt.eP_lA);
        dt.eB_lSnorm=dt.eB_lS./norm(dt.eB_lS);
        
        tmod=fitlm(dt,'eP_lAnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM=find(strcmp(tmod.PredictorNames,'eATnorm'),1,'first');
        IdxBS=find(strcmp(tmod.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.BE(sj+nsub)=tmod.Coefficients.Estimate(IdxBS);
        IndRegressions.BA(sj+nsub)=tmod.Coefficients.Estimate(IdxBM);
        tempCode=cell2mat(sjcode);
        IndRegressions.FM(sj+nsub)=FM(str2num(tempCode(end-2:end)));
        IndRegressions.vel(sj+nsub)=velsS(str2num(tempCode(end-2:end)));
        R2=uncenteredRsquared(tmod);IndRegressions.longR2(sj+nsub)=R2.uncentered;
        IndRegressions.pBE(sj+nsub)=tmod.Coefficients.pValue(IdxBS);
        IndRegressions.pBA(sj+nsub)=tmod.Coefficients.pValue(IdxBM);
        longCI=tmod.coefCI;
        IndRegressions.longCI(sj+nsub)=diff(longCI(1,:))/2;
        [IndRegressions.pLong(sj+nsub),dummy]=coefTest(tmod);
        
        
        tmod2=fitlm(dt,'eB_lSnorm~eAnorm+eATnorm-1','RobustOpts',rob);
        IdxBM2=find(strcmp(tmod2.PredictorNames,'eATnorm'),1,'first');
        IdxBS2=find(strcmp(tmod2.PredictorNames,'eAnorm'),1,'first');
        IndRegressions.sBE(sj+nsub)=tmod2.Coefficients.Estimate(IdxBS2);
        IndRegressions.sBA(sj+nsub)=tmod2.Coefficients.Estimate(IdxBM2);
        R2=uncenteredRsquared(tmod2);IndRegressions.shortR2(sj+nsub)=R2.uncentered;
        IndRegressions.short_pBE(sj+nsub)=tmod2.Coefficients.pValue(IdxBS);
        IndRegressions.short_pBA(sj+nsub)=tmod2.Coefficients.pValue(IdxBM);
        shortCI=tmod2.coefCI;
        IndRegressions.shortCI(sj+nsub)=diff(shortCI(1,:))/2;
        try
         [IndRegressions.pShort(sj+nsub),dummy]=coefTest(tmod2);
        catch
            IndRegressions.pShort(sj+nsub)=NaN;
        end
        
        clear dt c sjcode tmod IdxBM IdxBS tmod2 IdxBM2 IdxBS2 
        
    end
    
    %normalize each variable in a table
    function [normTable] = fcnNormTable(Table)
    vnames=Table.Properties.VariableNames;
    newvnames=strcat(vnames,'norm');
    for n=1:length(vnames)
        Table.(newvnames{n})=Table.(vnames{n})./norm(Table.(vnames{n}));
    end
    normTable=Table;
    end