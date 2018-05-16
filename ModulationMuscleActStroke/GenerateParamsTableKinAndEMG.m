%%Generate ParamsTable
clear all
close all
%%Kinematic outcomes

%% read data
matDataDir='C:\Users\did35\OneDrive - University of Pittsburgh\Projects\Modulation of muscle activity in stroke\GroupData\'
fileName='groupedParamsForKinAnalysis';
%%
matchSpeedFlag=0;
removeMissing=false;

loadName=[matDataDir,fileName]; 
load(loadName)

patients2=patients.removeSubs({'P0007'});
controls2=controls.removeSubs({'C0007'});
patients2=patients2.removeBadStrides;
controls2=controls2.removeBadStrides;

eF=1;
eL=1;
% eps=defineEpochs({'Base','eA','lA','eP','lP'},{'TM base','Adaptation','Adaptation','Washout','Washout'},[-40 15 -40 15 -40],...
%     [eF,eF,eF,eF,eF],[eL,eL,eL,eL,eL],'nanmean');

eps=defineEpochs({'Base','eA','lA','eP'},{'TM base','Adaptation','Adaptation','Washout'},[-40 15 -40 15],...
    [eF,eF,eF,eF],[eL,eL,eL,eL],'nanmean');
labels={'spatialContributionPNorm','stepTimeContributionPNorm','velocityContributionPNorm','netContributionPNorm','alphaFast','alphaSlow','xFast','xSlow'};
%labels={'spatialContributionPNorm','stepTimeContributionPNorm','velocityContributionPNorm','netContributionPNorm'};

t=table;
t.group=cell(30,1);
t.group(1:15,1)={'Control'};
t.group(16:30,1)={'Stroke'};

%get the data for specific epochs in the Table
for p=1:length(labels) 
        for e=1:length(eps)
            t.([cell2mat(eps(e,:).Properties.ObsNames),'_',labels{p}])=[squeeze(controls2.getEpochData(eps(e,:),labels{p}));...
                squeeze(patients2.getEpochData(eps(e,:),labels{p}))];
        end

       
        t.(['eA_B_',labels{p}])=[squeeze(controls2.getEpochData(eps(2,:),labels{p})-controls2.getEpochData(eps(1,:),labels{p}));...
            squeeze(patients2.getEpochData(eps(2,:),labels{p})-patients2.getEpochData(eps(1,:),labels{p}))];
        t.(['lA_B_',labels{p}])=[squeeze(controls2.getEpochData(eps(3,:),labels{p})-controls2.getEpochData(eps(1,:),labels{p}));...
            squeeze(patients2.getEpochData(eps(3,:),labels{p})-patients2.getEpochData(eps(1,:),labels{p}))];
        t.(['eP_lA_',labels{p}])=[squeeze(controls2.getEpochData(eps(4,:),labels{p})-controls2.getEpochData(eps(3,:),labels{p}));...
            squeeze(patients2.getEpochData(eps(4,:),labels{p})-patients2.getEpochData(eps(3,:),labels{p}))];
        t.(['eP_B_',labels{p}])=[squeeze(controls2.getEpochData(eps(4,:),labels{p})-controls2.getEpochData(eps(1,:),labels{p}));...
            squeeze(patients2.getEpochData(eps(4,:),labels{p})-patients2.getEpochData(eps(1,:),labels{p}))];
end 

%load datafile for EMG
clear patients controls patients2 controls2

fileName='groupedParams30HzPT11Fixed';
loadName=[matDataDir,fileName]; 
load(loadName)

patients2=patients.removeSubs({'P0007'});
controls2=controls.removeSubs({'C0007'});
groups{1}=controls2;
groups{2}=patients2;

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

[dataE,EMGlabels,dummy]=getPrefixedEpochData(groups{1}.adaptData{1},newLabelPrefix,eps,1);
EMGlabels=EMGlabels(:);

for p=1:length(EMGlabels) 
    templabel=strrep(EMGlabels{p},' ','_');
        for e=1:length(eps)
            t.([cell2mat(eps(e,:).Properties.ObsNames),'_',templabel])=[squeeze(groups{1}.getEpochData(eps(e,:),EMGlabels{p}));...
                squeeze(groups{2}.getEpochData(eps(e,:),EMGlabels{p}))];
        end
end

clear groups patients controls patients2 controls2

%load file with angles
fileName='groupParamsWithAngles';
%%
loadName=[matDataDir,fileName]; 
load(loadName)

patients2=patients.removeSubs({'P0007'});
controls2=controls.removeSubs({'C0007'});
eps2=defineEpochs({'Base','eA','lA','eP'},{'TM base','Adaptation','Adaptation','Washout'},[-40 15 -40 15],...
    [eF,eF,eF,eF],[eL,eL,eL,eL],'nanmedian');
for e=1:length(eps)
            t.([cell2mat(eps(e,:).Properties.ObsNames),'_skneeAngleAtSHS'])=[squeeze(controls2.getEpochData(eps(e,:),'skneeAngleAtSHS'));...
                squeeze(patients2.getEpochData(eps(e,:),'skneeAngleAtSHS'))];
             t.([cell2mat(eps(e,:).Properties.ObsNames),'_fkneeAngleAtFHS'])=[squeeze(controls2.getEpochData(eps(e,:),'fkneeAngleAtFHS'));...
                squeeze(patients2.getEpochData(eps(e,:),'fkneeAngleAtFHS'))];
end

fileName='RegressionResults';
loadName=[matDataDir,fileName]; 
load(loadName)

demVars=tALL.Properties.VariableNames(2:end);
for d=1:length(demVars)
    t.(demVars{d})=tALL.(demVars{d});
end

        