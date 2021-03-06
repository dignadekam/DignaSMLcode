%% Group assessments
clear all
close all
clc

matfilespath='Z:\SubjectData\E01 Synergies\mat\HPF30\';

strokesNames={'P0001','P0002','P0003','P0004','P0005','P0006','P0008','P0009','P0010','P0011','P0012','P0013','P0014','P0015','P0016'};%P0007 was removed because of contralateral atrophy
controlsNames={'C0001','C0002','C0003','C0004','C0005','C0006','C0008','C0009','C0010','C0011','C0012','C0013','C0014','C0015','C0016'}; %C0000 is removed because it is not a control for anyone, C0007 is removed because it was control for P0007

%load ([matfilespath,'groupedParams_wMissingParameters.mat']);
load ([matfilespath,'groupedParams30HzPT11Fixed.mat']);

%define groups
groups{1}=controls.getSubGroup(controlsNames);
groups{2}=patients.getSubGroup(strokesNames);

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

fi=figure('Name','Individual Groups');
ha=tight_subplot(2,4,[.03 .005],.04,.04);
pc1=ha(1,1);
ps1=ha(2,1);
pc2=ha(1,2);
ps2=ha(2,2);
pc3=ha(1,3);
ps3=ha(2,3);
pc4=ha(1,4);
ps4=ha(2,4);

fb=figure('Name','Between Groups');
hb=tight_subplot(2,4,[.03 .005],.04,.04);
pd1=hb(1,1);
pd2=hb(1,2);
pd3=hb(1,3);
pd4=hb(1,3);

eE=1;
eL=1;
evLabel={'iHS','','cTO','','','','cHS','','iTO','','',''};
%set axes;



[eps] = defineEpochs({'lA'},{'Adaptation'}',[-40],[eE],[eL],'nanmean');
[reps] = defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],'nanmean');
[fi,fb,pc1,ps1,pd1,pvalc1,pvals1,pvalb1,hc1,hs1,hb1,dataEc1,dataEs1,dataBinaryc1,dataBinarys1]=plotBGcompV2(fi,fb,pc1,ps1,pd1,eps,reps,newLabelPrefix,groups,0.1,0.1,'nanmedian');

[eps] = defineEpochs({'eA'},{'Adaptation'}',[15],[eE],[eL],'nanmean');
[reps] = defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],'nanmean');
[fi,fb,pc2,ps2,pd2,pvalc2,pvals2,pvalb2,hc2,hs2,hb2,dataEc2,dataEs2,dataBinaryc2,dataBinarys2]=plotBGcompV2(fi,fb,pc2,ps2,pd2,eps,reps,newLabelPrefix,groups,0.1,0.1,'nanmedian');

[eps] = defineEpochs({'eP'},{'Washout'}',[15],[eE],[eL],'nanmean');
[reps] = defineEpochs({'lA'},{'Adaptation'}',[-40],[eE],[eL],'nanmean');
[fi,fb,pc3,ps3,pd3,pvalc3,pvals3,pvalb3,hc3,hs3,hb3,dataEc3,dataEs3,dataBinaryc3,dataBinarys3]=plotBGcompV2(fi,fb,pc3,ps3,pd3,eps,reps,newLabelPrefix,groups,0.1,0.1,'nanmedian');

[eps] = defineEpochs({'eP'},{'Washout'}',[15],[eE],[eL],'nanmean');
[reps] = defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],'nanmean');
[fi,fb,pc4,ps4,pd4,pvalc4,pvals4,pvalb4,hc4,hs4,hb4,dataEc4,dataEs4,dataBinaryc4,dataBinarys4]=plotBGcompV2(fi,fb,pc4,ps4,pd4,eps,reps,newLabelPrefix,groups,0.1,0.1,'nanmedian');


%TO DO set colormap for nonparameteric
% whiteMiddleColorMap;
% set(fi,'ColorMap',map2);
set(ha(1:2,1),'CLim',[-1 1].*0.5);
set(ha(1:2,2:end),'YTickLabels',{},'CLim',[-1 1].*0.5);
set(ha(1,:),'XTickLabels','');
set(ha(2,:),'XTick',(0:numel(evLabel)-1)/12,'CLim',[-1 1]*0.5);
set(ha,'FontSize',8)
pos=get(ha(1,end),'Position');
axes(ha(1,end))
colorbar
set(ha(1,end),'Position',pos);


set(hb(1:2,2:end),'YTickLabels',{},'CLim',[-1 1].*15);
%set(ha(1,:),'XTickLabels','');
set(hb,'XTick',(0:numel(evLabel)-1)/12,'CLim',[-1 1]*15);
set(hb,'FontSize',8)
pos=get(hb(1,end),'Position');
axes(hb(1,end))
colorbar
set(hb(1,end),'Position',pos);
set(hb(2,:),'Visible','off');

