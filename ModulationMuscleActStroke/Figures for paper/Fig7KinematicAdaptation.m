%% Assuming that the variables groups() exists (From N19_loadGroupedData)
clear all
close all
%% read data
[loadName,matDataDir]=uigetfile('*.mat');
%%
matchSpeedFlag=0;
removeMissing=false;
binWidth=10;

loadName=[matDataDir,loadName]; 
load(loadName)

patientFastList=strcat('P00',{'01','02','05','08','09','10','13','14','15'});%P016 removed %Patients above .72m/s, which is the group mean. N=10. Mean speed=.88m/s. Mean FM=29.5 (vs 28.8 overall)
controlsSlowList=strcat('C00',{'01','02','04','05','06','09','10','12','16'}); %C07 removed%Controls below 1.1m/s (chosen to match pop size), N=10. Mean speed=.9495m/s

removeP07Flag=1;
if removeP07Flag
    patients2=patients.removeSubs({'P0007'});
    controls2=controls.removeSubs({'C0007'});
    %patientsUnbiased2=patients2.removeBias;
    %controlsUnbiased2=controls2.removeBias;
end
switch matchSpeedFlag
    case 1 %Speed matched groups
%         patients2=patients2.getSubGroup(patientFastList).removeBadStrides;
%         controls2=controls2.getSubGroup(controlsSlowList).removeBadStrides;
        patients2=patients2.getSubGroup(patientFastList);
        controls2=controls2.getSubGroup(controlsSlowList);
        %patientsUnbiased2=patientsUnbiased2.getSubGroup(patientFastList).removeBadStrides;
        %controlsUnbiased2=controlsUnbiased2.getSubGroup(controlsSlowList).removeBadStrides;
    case 0 %Full groups
       % patients2=patients2.removeBadStrides;
       % controls2=controls2.removeBadStrides;
        %patientsUnbiased2=patients2.removeBadStrides.removeBias;
        %controlsUnbiased2=controls2.removeBadStrides.removeBias;   
end

groups{1}=controls2;
groups{2}=patients2;


colors=[0.4 0.7 0.7;0.9 0.5 0.9];

eF=1;
eL=1;
% eps=defineEpochs({'Base','eA','lA','eP','lP'},{'TM base','Adaptation','Adaptation','Washout','Washout'},[-40 15 -40 15 -40],...
%     [eF,eF,eF,eF,eF],[eL,eL,eL,eL,eL],'nanmean');

%strides for group epoch bars
eps=defineEpochs({'Base','eA','lA','eP'},{'TM base','Adaptation','Adaptation','Washout'},[-40 15 -40 15],...
    [eF,eF,eF,eF],[eL,eL,eL,eL],'nanmean');
%strides for time courses
eps2=defineEpochs({'Base','eA','lA','eP'},{'TM base','Adaptation','Adaptation','Washout'},[-40 500 -40 200],...
    [eF,eF,eF,eF],[eL,eL,eL,eL],'nanmean');
labels={'spatialContributionPNorm','stepTimeContributionPNorm','velocityContributionPNorm','netContributionPNorm'};
%labels={'spatialContributionPNorm','stepTimeContributionPNorm','velocityContributionPNorm','netContributionPNorm'};

groupsUnbiased{1}=groups{1}.removeBadStrides.removeBaselineEpoch(eps(1,:),[]);
groupsUnbiased{2}=groups{2}.removeBadStrides.removeBaselineEpoch(eps(1,:),[]);


%[fh,ph,allData]=plotGroupedTimeAndEpochBars(adaptDataGroups,labels,epochs,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,groupNames,medianFlag);
%[fh,ph,allData]=adaptationData.plotGroupedTimeAndEpochBars(groups,labels,eps,10,0,0,0,colors,0,{'control','stroke'},0,1,0,0.05,0,0,1,0);
fh=figure;
fullscreen
xpos=[0.03 0.51];
ypos=[0.7722 0.5370 0.3017 0.0665];
w=[0.45 0.2310];
h=0.1820;

M=length(labels);
for i=1:M
    ph(i,1)=subplot(M,3,[1:2]+3*(i-1));
    set(ph(i,1),'Position',[xpos(1),ypos(i),w(1),h])
    ph(i,2)=subplot(M,3,[3]+3*(i-1));
    set(ph(i,2),'Position',[xpos(2),ypos(i),w(2),h])
end


%plot time courses
for i=1:M
    hold(ph(i,1))
    for g=1:length(groupsUnbiased);
        Inds=0;
        meanData=[];
        minData=[];
        maxData=[];
        for E=1:length(eps2)
            if eps2.EarlyOrLate(E)==0;
                numberOfStrides=eps2.Stride_No(E)*-1;
            else numberOfStrides=eps2.Stride_No(E);
            end
            
            %get data
            dt=getGroupedData(groupsUnbiased{g},labels{i},eps2.Condition{E},0,numberOfStrides,eps2.ExemptFirst(E),eps2.ExemptLast(E),1);
            dt=squeeze(dt{1});
            %smoothing
            start=1:size(dt,1)-(binWidth-1);
            stop=start+binWidth-1;
            nbins=length(start);
            
            dt2=NaN(length(start),size(dt,2));
            %running average for each subject
            for s=1:size(dt,2)
                for binNum=1:length(start)
                    dt2(binNum,s)=nanmean(dt(start(binNum):stop(binNum),s));
                end
            end
            if isempty(Inds)
                Inds=1:size(dt2,1);
            else
                Inds=Inds(end)+21:Inds(end)+size(dt2,1);
            end
           %plot here directly, ohterwise patches mess up
            plot(ph(i,1),Inds,nanmean(dt2,2),'ok','MarkerSize',5,'MarkerFaceColor',colors(g,:),'MarkerEdgeColor',colors(g,:)-0.3)
            patch(ph(i,1),[Inds fliplr(Inds)],[nanmean(dt2,2)+(nanstd(dt2')'./sqrt(size(dt2,2))); flipud(nanmean(dt2,2)-(nanstd(dt2')'./sqrt(size(dt2,2))))],colors(g,:),'FaceAlpha',0.5,'LineStyle','none');
            
%             meanData=[meanData;nan(20,1);nanmean(dt2,2)];%group AVG
%             minData=[minData;nan(20,1);nanmean(dt2,2)-nanstd(dt2')'./sqrt(size(dt2,2))];%mean-SEM
%             maxData=[maxData;nan(20,1);nanmean(dt2,2)+nanstd(dt2')'./sqrt(size(dt2,2))];%mean+SEM
            
        end
%         meanData=meanData(21:end,1);
%         minData=minData(21:end,1);
%         maxData=maxData(21:end,1);
        
        %plot Data
       
        
        
        
    end
end

%get epoch data and generate data for plot
for i=1:length(groups)
    contrasts{i}=table;
    for p=1:length(labels) 
        contrasts{i}.(['eA_B_',labels{p}])=squeeze(groups{i}.getEpochData(eps(2,:),labels{p})-groups{i}.getEpochData(eps(1,:),labels{p}));
        contrasts{i}.(['lA_B_',labels{p}])=squeeze(groups{i}.getEpochData(eps(3,:),labels{p})-groups{i}.getEpochData(eps(1,:),labels{p}));
        contrasts{i}.(['eP_lA_',labels{p}])=squeeze(groups{i}.getEpochData(eps(4,:),labels{p})-groups{i}.getEpochData(eps(3,:),labels{p}));
        contrasts{i}.(['eP_B_',labels{p}])=squeeze(groups{i}.getEpochData(eps(4,:),labels{p})-groups{i}.getEpochData(eps(1,:),labels{p}));
    end    
end
contrastnames={'eA_B','lA_B','eP_lA','eP_B'};

spatialDataControls=NaN(length(controls2.adaptData),4);
spatialDataStroke=NaN(length(patients2.adaptData),4);
temporalDataControls=NaN(length(controls2.adaptData),4);
temporalDataStroke=NaN(length(patients2.adaptData),4);
velocityDataControls=NaN(length(controls2.adaptData),4);
velocityDataStroke=NaN(length(patients2.adaptData),4);
netDataControls=NaN(length(controls2.adaptData),4);
netDataStroke=NaN(length(patients2.adaptData),4);

for c=1:length(contrastnames)
    spatialDataControls(:,c)=contrasts{1}.([contrastnames{c},'_','spatialContributionPNorm']);
    spatialDataStroke(:,c)=contrasts{2}.([contrastnames{c},'_','spatialContributionPNorm']);
    temporalDataControls(:,c)=contrasts{1}.([contrastnames{c},'_','stepTimeContributionPNorm']);
    temporalDataStroke(:,c)=contrasts{2}.([contrastnames{c},'_','stepTimeContributionPNorm']);
    velocityDataControls(:,c)=contrasts{1}.([contrastnames{c},'_','velocityContributionPNorm']);
    velocityDataStroke(:,c)=contrasts{2}.([contrastnames{c},'_','velocityContributionPNorm']);
    netDataControls(:,c)=contrasts{1}.([contrastnames{c},'_','netContributionPNorm']);
    netDataStroke(:,c)=contrasts{2}.([contrastnames{c},'_','netContributionPNorm']);
    
end

%run paired t-test stats with Bonferroni correction for each parameter
stat=table;
stat.param=repmat({''},length(contrastnames)*length(labels),1);
row=1;
for l=1:length(labels)
    for c=1:length(contrastnames)
        stat.param(row)=labels(l);
        stat.contrast(row)=contrastnames(c);
        [h,p,ci]=ttest2(contrasts{1}.([contrastnames{c},'_',labels{l}]),contrasts{2}.([contrastnames{c},'_',labels{l}]));
        %[p,h]=ranksum(contrasts{1}.([contrastnames{c},'_',labels{l}]),contrasts{2}.([contrastnames{c},'_',labels{l}]));ci=[0 0];
        stat.meandif(row)=nanmean(contrasts{1}.([contrastnames{c},'_',labels{l}]))-nanmean(contrasts{2}.([contrastnames{c},'_',labels{l}]));
        stat.lowerbound(row)=ci(1);
        stat.upperboutn(row)=ci(2);
        stat.pval(row)=p;
        stat.pvalBonferroni(row)=p*length(contrastnames);   
        row=row+1;
        
    end
end

set(ph(:,:),'FontSize',16,'TitleFontSizeMultiplier',1.1,'box','off');


%generate plots for between epoch measures
xval=[1 2;4 5;7 8;10 11];
nc=size(spatialDataControls,1);
ns=size(spatialDataStroke,1);
hold(ph(1,2));
bar(ph(1,2),xval(:,1),nanmean(spatialDataControls),'FaceColor',colors(1,:),'BarWidth',0.2)
errorbar(ph(1,2),xval(:,1),nanmean(spatialDataControls),nanstd(spatialDataControls)./sqrt(nc),'Color','k','LineWidth',2,'LineStyle','none')
bar(ph(1,2),xval(:,2),nanmean(spatialDataStroke),'FaceColor',colors(2,:),'BarWidth',0.2)
errorbar(ph(1,2),xval(:,2),nanmean(spatialDataStroke),nanstd(spatialDataStroke)./sqrt(ns),'Color','k','LineWidth',2,'LineStyle','none')
plot(ph(1,2),xval(1,:),[0.15 0.15],'-k','LineWidth',2)
ll=findobj(ph(1,2),'Type','Bar');
legend(ll(end:-1:1),{'CONTROL','STROKE'},'box','off')


hold(ph(2,2));
bar(ph(2,2),xval(:,1),nanmean(temporalDataControls),'FaceColor',colors(1,:),'BarWidth',0.2)
errorbar(ph(2,2),xval(:,1),nanmean(temporalDataControls),nanstd(temporalDataControls)./sqrt(nc),'Color','k','LineWidth',2,'LineStyle','none')
bar(ph(2,2),xval(:,2),nanmean(temporalDataStroke),'FaceColor',colors(2,:),'BarWidth',0.2)
errorbar(ph(2,2),xval(:,2),nanmean(temporalDataStroke),nanstd(temporalDataStroke)./sqrt(ns),'Color','k','LineWidth',2,'LineStyle','none')

hold(ph(3,2));
bar(ph(3,2),xval(:,1),nanmean(velocityDataControls),'FaceColor',colors(1,:),'BarWidth',0.2)
errorbar(ph(3,2),xval(:,1),nanmean(velocityDataControls),nanstd(velocityDataControls)./sqrt(nc),'Color','k','LineWidth',2,'LineStyle','none')
bar(ph(3,2),xval(:,2),nanmean(velocityDataStroke),'FaceColor',colors(2,:),'BarWidth',0.2)
errorbar(ph(3,2),xval(:,2),nanmean(velocityDataStroke),nanstd(velocityDataStroke)./sqrt(ns),'Color','k','LineWidth',2,'LineStyle','none')

hold(ph(4,2));
bar(ph(4,2),xval(:,1),nanmean(netDataControls),'FaceColor',colors(1,:),'BarWidth',0.2)
errorbar(ph(4,2),xval(:,1),nanmean(netDataControls),nanstd(netDataControls)./sqrt(nc),'Color','k','LineWidth',2,'LineStyle','none')
bar(ph(4,2),xval(:,2),nanmean(netDataStroke),'FaceColor',colors(2,:),'BarWidth',0.2)
errorbar(ph(4,2),xval(:,2),nanmean(netDataStroke),nanstd(netDataStroke)./sqrt(ns),'Color','k','LineWidth',2,'LineStyle','none')
plot(ph(4,2),xval(1,:),[-0.3 -0.3],'-k','LineWidth',2)

%set titles and labels
set(ph(:,2),'XTick',nanmean(xval,2),'XTickLabel',{''},'XLim',[0.5 11.5])
set(ph(4,2),'XTickLabel',{'eA_B_A_S_E','lA_B_A_S_E','eP_l_A','eP_B_A_S_E'})
set(ph(:,1),'XTick',[115 362 625])
set(ph(4,1),'XTickLabel',{'BASE','ADAPTATION','POST-ADAPTATION'})

set(ph(1,1),'YLim',[-0.1 0.2],'YTick',[-0.1 0 0.1 0.2])
set(ph(2,1),'YLim',[-0.05 0.2],'YTick',[0 0.1 0.2])
set(ph(3,1),'YLim',[-0.4 0.2],'YTick',[-0.4 -0.2 0 0.2])
set(ph(4,1),'YLim',[-0.4 0.2],'YTick',[-0.4 -0.2 0 0.2])

set(ph(1,2),'YLim',[-0.2 0.2],'YTick',[-0.2 0 0.2])
set(ph(2,2),'YLim',[-0.2 0.2],'YTick',[-0.2 0 0.2])
set(ph(3,2),'YLim',[-0.4 0.4],'YTick',[-0.4 -0.2 0 0.2 0.4])
set(ph(4,2),'YLim',[-0.4 0.2],'YTick',[-0.4 -0.2 0 0.2])

title(ph(1,1),'StepPosition')
title(ph(2,1),'StepTime')
title(ph(3,1),'StepVelocity')
title(ph(4,1),'StepAsym')
title(ph(1,2),'StepPosition')
title(ph(2,2),'StepTime')
title(ph(3,2),'StepVelocity')
title(ph(4,2),'StepAsym')

set(gcf,'Renderer','painters');

%set(fh,'Position',[0 0 250 250])