%fh=figure('Units','Normalized','Position',[0 0 0. 0.3]);
figuresColorMap;
fh=figure('Units','Normalized','Position',[0 0 .55 .35]);
    
auxF=[0;.35;-.3];
auxS=[-.35;.35;.2];
for k=[2,3,1]
    switch k
        case 1 %eA
            aux1=auxF;
            aux2=auxS;
            tt='EarlyA';
       case 3
            tt='\beta_MEarlyA*';
            aux1=auxS;
            aux2=auxF;     
       case 2
            tt='-\beta_SEarlyA';
            aux1=-auxF;
            aux2=-auxS;     
    end
ax=axes;
%ax.Position=[0.05+(k-1)*.08 .05 .2 .35];
ax.Position=[0.05+(k-1)*.1 .05 .2 .35];
I=imshow(size(map,1)*(aux1+.5),flipud(map),'Border','tight');
rectangle('Position',[.5 .5 1 3],'EdgeColor','k')
%%Add arrows
hold on
quiver(ones(size(aux1)),[1:numel(aux1)]'+.4*sign(aux1),zeros(size(aux1)),-.7*sign(aux1),0,'Color','k','LineWidth',2)
if k==1
    text(1.7,1,'m1','Clipping','off','FontSize',20,'FontWeight','bold')
    text(1.7,2,'m2','Clipping','off','FontSize',20,'FontWeight','bold')
    text(1.7,3,'m3','Clipping','off','FontSize',20,'FontWeight','bold')
end

ax=axes;
%ax.Position=[.05+(k-1)*.08 .45 .2 .35];
ax.Position=[.05+(k-1)*.1 .45 .2 .35];
I=imshow(size(map,1)*(aux2+.5),flipud(map),'Border','tight');
rectangle('Position',[.5 .5 1 3],'EdgeColor','k')
%%Add arrows
hold on
quiver(ones(size(aux1)),[1:numel(aux1)]'+.4*sign(aux2),zeros(size(aux1)),-.7*sign(aux2),0,'Color','k','LineWidth',2)

set(gca,'XTickLabel','','YTickLabel','','XTick','','YTick','')
text(.6,0,tt,'Clipping','off','FontSize',20,'FontWeight','bold')
if k==1
    text(1.7,1,'m1','Clipping','off','FontSize',20,'FontWeight','bold')
    text(1.7,2,'m2','Clipping','off','FontSize',20,'FontWeight','bold')
    text(1.7,3,'m3','Clipping','off','FontSize',20,'FontWeight','bold')
end


end

% text(-1.8,-.65,'eP-lA','Clipping','off','FontSize',14,'FontWeight','bold')
% plot([-3.5 1.5],-.3*[1 1],'k','LineWidth',2,'Clipping','off')
%plot(-4*[1 1],[.5 7],'k','LineWidth',1,'Clipping','off')

%Add lines on fast/slow:
ccc=get(gca,'ColorOrder');
plot(0.3*[1 1],3.45+[.5 3.5],'LineWidth',4,'Color',ccc(1,:),'Clipping','off')
text(-0.1,6.25,'FAST','Color',ccc(1,:),'Rotation',90,'FontSize',20,'FontWeight','bold')
plot(0.3*[1 1],[.5 3.5],'LineWidth',4,'Color',ccc(2,:),'Clipping','off')
text(-0.1,3,'SLOW','Color',ccc(2,:),'Rotation',90,'FontSize',20,'FontWeight','bold')

text(-1,-0.8,'EarlyP-LateA=','FontSize',20,'FontWeight','bold')
set(gcf,'Renderer','painters');