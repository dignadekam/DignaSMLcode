%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot correlation matrix of selected parameters%
% Parmeters can be self-selected by user        %
%                                               %
% - Input: Table with parameters                %
%                                               %
% - Output: Correlation matrix                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%GenerateParamsTable

varnames=T.Properties.VariableNames';
xvar=listdlg('PromptString','Select Predictors','SelectionMode','multiple','ListString',varnames);xvarnames=varnames(xvar);
yvar=listdlg('PromptString','Select Dependent Variables','SelectionMode','multiple','ListString',varnames);yvarnames=varnames(yvar);
xval=[];for l=1:length(xvar);xval(:,l)=T.(xvarnames{l});end
yval=[];for l=1:length(yvar);yval(:,l)=T.(yvarnames{l});end
[h,ax,bigax]=gplotmatrix(xval,yval,T.group,'k','o',12,[],[],xvarnames,yvarnames);

%colcodes2=flipud(colcodes(groupInd,:));
colcodes2=[0.6 0 0.6;0.2 0.2 1;0.6 0.6 0.6];
%colcodes2=[0.6 0.6 0.6];
for a = 1:size(ax,1)
    for c = 1:size(ax,2)
    hold(ax(a,c))
    ll=findobj(ax(a,c),'Type','Line');
    xdata=[];
    ydata=[];
    for n=1:length(ll)
        set(ll(n), 'MarkerFaceColor', colcodes2(n,:));
        xdata=[xdata;ll(n).XData'];
        ydata=[ydata;ll(n).YData'];
    end
    Idx=find(~isnan(xdata));
    xdata=xdata(Idx);ydata=ydata(Idx);
    Idx2=find(~isnan(ydata));
    xdata=xdata(Idx2);ydata=ydata(Idx2);
    
    
    
    [r,m,b] = regression(xdata,ydata,'one');
    rfit=b+xdata.*m;
    plot(ax(a,c),xdata,rfit,'LineWidth',2,'Color',[0.5 0.5 0.5])
    %lsline(ax);
    [rho,p]=corr(xdata,ydata,'Type','Spearman');
    xpos=get(ax(a,c),'XLim');ypos=get(ax(a,c),'YLim');
    text(ax(a,c),mean(xpos),max(ypos),['RHO = ',num2str(rho),' p = ',num2str(p)],'FontSize',16,'FontWeight','bold');
    set(ax(a,c),'FontSize',14)
    clear xdata r m b rfit ydata
    end
    
end
