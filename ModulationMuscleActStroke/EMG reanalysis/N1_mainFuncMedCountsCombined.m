%% Group assessments
clear all
close all
clc

matfilespath='Z:\Users\Digna\Projects\Modulation of muscle activity in stroke\EMG reanalysis\Data\';

strokesNames={'P0001','P0002','P0003','P0004','P0005','P0006','P0008','P0009','P0010','P0011','P0012','P0013','P0014','P0015','P0016'};
controlsNames={'C0001','C0002','C0003','C0004','C0005','C0006','C0008','C0009','C0010','C0011','C0012','C0013','C0014','C0015','C0016'}; %C0000 is removed because it is not a control for anyone, plus it has

load ([matfilespath,'groupedParams30Hz.mat']);

%define groups
groups{1}=controls.getSubGroup(controlsNames);
groups{2}=patients.getSubGroup(strokesNames);

%% Get normalized parameters:
%Define parameters we care about:
mOrder={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'HIP', 'ADM', 'TFL', 'GLU'};
nMusc=length(mOrder);
type='s';
labelPrefix=fliplr([strcat('f',mOrder) strcat('s',mOrder)]); %To display
%labelPrefix=fliplr([strcat('fmed',mOrder) strcat('smed',mOrder)]); %To display
labelPrefixLong= strcat(labelPrefix,['_' type]); %Actual names

%Renaming normalized parameters, for convenience:
for k=1:length(groups)
    ll=groups{k}.adaptData{1}.data.getLabelsThatMatch('^Norm');
    l2=regexprep(regexprep(ll,'^Norm',''),'_s','s');
    groups{k}=groups{k}.renameParams(ll,l2);
    
%     l3=groups{k}.adaptData{1}.data.getLabelsThatMatch('^medf');
%     l4=regexprep(l3,'medf','fmed');
%     groups{k}=groups{k}.renameParams(l3,l4);
%     
%     l5=groups{k}.adaptData{1}.data.getLabelsThatMatch('^meds');
%     l6=regexprep(l5,'^meds','smed');
%     groups{k}=groups{k}.renameParams(l5,l6);
end
newLabelPrefix=fliplr(strcat(labelPrefix,'s'));

f=figure;
eE=1;
eL=1;
evLabel={'iHS','','cTO','','','','cHS','','iTO','','',''};
%set axes;

ha=tight_subplot(3,5,[.03 .005],.04,.04);
pc1=ha(1);
ps1=ha(2);
pc2=ha(4);
ps2=ha(5);
pc3=ha(7);
ps3=ha(8);
pd1=ha(3);
pd2=ha(6);
pd3=ha(9);

% pc1=subplot(3,3,1);
% ps1=subplot(3,3,4);
% pc2=subplot(3,3,2);
% ps2=subplot(3,3,5);
% pc3=subplot(3,3,3);
% ps3=subplot(3,3,6);
% pd1=subplot(3,3,7);
% pd2=subplot(3,3,8);
% pd3=subplot(3,3,9);
% %plot late adapt vs baseline
%late adapt-base



[eps] = defineEpochs({'lA'},{'Adaptation'}',[-40],[eE],[eL],'nanmedian');
[reps] = defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],'nanmedian');

[f,p1c,ps1,pd1,pvalc1,pvals1,pvalb1,hc1,hs1,hb1,dataEc1,dataEs1,dataBinaryc1,dataBinarys1]=plotBGcompCountsCombined(f,pc1,ps1,pd1,eps,reps,0,newLabelPrefix,groups,0.05,0.1,'nanmedian',evLabel);

%ealy adapt-base

[eps] = defineEpochs({'eA'},{'Adaptation'}',[15],[eE],[eL],'nanmedian');
[reps] = defineEpochs({'Base'},{'TM base'}',[-40],[eE],[eL],'nanmedian');
[f,pc2,ps2,pd2,pvalc2,pvals2,pvalb2,hc2,hs2,hb2,dataEc2,dataEs2,dataBinaryc2,dataBinarys2]=plotBGcompCountsCombined(f,pc2,ps2,pd2,eps,reps,0,newLabelPrefix,groups,0.05,0.1,'nanmedian',evLabel);

%ealy post adapt-late lA

[eps] = defineEpochs({'eP'},{'Washout'}',[15],[eE],[eL],'nanmedian');
[reps] = defineEpochs({'lA'},{'Adaptation'}',[-40],[eE],[eL],'nanmedian');
[f,pc3,ps3,pd3,pvalc3,pvals3,pvalb3,hc3,hs3,hb3,dataEc3,dataEs3,dataBinaryc3,dataBinarys3]=plotBGcompCountsCombined(f,pc3,ps3,pd3,eps,reps,0,newLabelPrefix,groups,0.05,0.1,'nanmedian',evLabel);

set(ha(1:2,1),'CLim',[-1 1].*0.5);
set(ha(1:2,2:end),'YTickLabels',{},'CLim',[-1 1].*.5);
set(ha(2,1:end),'XTickLabels',{},'CLim',[-1 1].*.5);
set(ha(3,1),'CLim',[-1 1].*15,'XTick',(0:numel(evLabel)-1)/12);
set(ha(3,2:end),'YTickLabels',{},'CLim',[-1 1].*15,'XTick',(0:numel(evLabel)-1)/12);
set(ha(1,:),'XTickLabels','');
%set(ha(2,:),'Title',[]);

set(ha,'FontSize',10)
pos=get(ha(1,3),'Position');
axes(ha(1,3))
colorbar
set(ha(1,3),'Position',pos);

pos=get(ha(3,3),'Position');
axes(ha(3,3))
colorbar
set(ha(3,3),'Position',pos);

set(ha(:,4:end),'Visible','off')

% xt=1:12;
% xc=xt-0.25;
% xs=xt+0.25;
% dtc=squeeze(dataEc3(:,11,1,:))';
% dts=squeeze(dataEs3(:,11,1,:))';
% ctemp=nanmedian(dataEc3,4);
% stemp=nanmedian(dataEs3,4);
% cstemp=nanstd(dtc);
% sstemp=nanstd(dts);

% figure
% hold on
% bar(xc,ctemp(:,11),'FaceColor','g','BarWidth',0.3);
% bar(xs,stemp(:,11),'FaceColor','r','BarWidth',0.3);
% errorbar(xc,ctemp(:,11),cstemp,'LineStyle','none','Color','k','LineWidth',2);
% errorbar(xs,stemp(:,11),sstemp,'LineStyle','none','Color','k','LineWidth',2);
% plot(xc,dtc,'ok')
% plot(xs,dts,'ok')
% ylabel('SMG eP-lA');

%plot diff checkerboards
% 
% ATS1=alignedTimeSeries(0,1,[nanmedian(dataEc1,4)-nanmedian(dataEs1,4)],labelPrefix,ones(1,12),evLabel);
% ATS1.plotCheckerboard(f,pd1);
% colorbar off
% 
% 
% ATS2=alignedTimeSeries(0,1,[nanmedian(dataEc2,4)-nanmedian(dataEs2,4)],labelPrefix,ones(1,12),evLabel);
% ATS2.plotCheckerboard(f,pd2);
% colorbar off
% 
% 
% ATS3=alignedTimeSeries(0,1,[nanmedian(dataEc3,4)-nanmedian(dataEs3,4)],labelPrefix,ones(1,12),evLabel);
% ATS3.plotCheckerboard(f,pd3);
% colorbar off









  
%run N19F_assessBetweenGroupedEMGEvolution.m%performs between groups analysis
