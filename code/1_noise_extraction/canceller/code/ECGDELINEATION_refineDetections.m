function [QRS_r]=ECGDELINEATION_refineDetections(Y,QRS,fs)

QRS_ori=QRS;


% calculamos un primer promedio con todas las detecciones
ns=length(Y);
Rm=mean(diff(QRS(2:end-1)));
%vent1=round(Rm.*0.45);      
%vent2=round(Rm.*0.65);

%Para ver si se parecen, tomo una ventana de 100 ms antes del pico del QRS y de 150 ms despues
vent1=round(0.1*fs);
vent2=round(0.15*fs);

losquenocaben=find(QRS-vent1<1 | QRS+vent2>ns);
QRS(losquenocaben)=[];
nQRS=length(QRS);
matrizparapromediar=zeros(nQRS,vent1+vent2+1);
for i=1:length(QRS);
    matrizparapromediar(i,:)=Y(QRS(i)-vent1:QRS(i)+vent2);
end
promedio=mean(matrizparapromediar).';

    
% Y ahora calculamos la correlacion con el promedio, buscando el desplazamiento que da una maxima correlacion

QRS_r=[];
for i=1:nQRS
    auxC=xcorr(matrizparapromediar(i,:),promedio,'coeff');
    despl_max=round(fs.*0.05);                          %Permito un refinamiento en la medida de 50 ms
    auxmaxcorr=max(auxC(length(promedio)-despl_max:length(promedio)+despl_max));
    maxcorr(i)=auxmaxcorr(1);
    m(i)=find(auxC(length(promedio)-despl_max:length(promedio)+despl_max)==maxcorr(i));
    despl(i)=m(i)-despl_max-1;
end

umbralcorr=min(mean(maxcorr)-3*std(maxcorr),0.95);
umbralcorr2=min(mean(maxcorr)-5*std(maxcorr),0.90);
separecen=find(maxcorr>umbralcorr);
QRS_r=sort([QRS(separecen)+despl(separecen) QRS_ori(losquenocaben)]);

QRS_r=sort([QRS_ori(losquenocaben) QRS_r]);

% Por ultimo busco los latidos que se desvien mucho del Rmedio  y los reviso para ver si nos hemos dejado algo
RR=diff(QRS_r);
desvRR=min(3*std(RR),mean(RR)./2);
RRlargo=find(diff(QRS_r)>(mean(RR)+desvRR));    
masQRS=[];
terminado=0;
while terminado==0
    for i=1:length(RRlargo)
        trozo=Y(QRS_r(RRlargo(i))+vent2:QRS_r(RRlargo(i)+1)-vent1);
        auxC2=xcorr(trozo,promedio);
        maxcorr2=max(auxC2);
        m=find(auxC2==maxcorr2);
        posmaxcorr=m-length(trozo)+vent1+QRS_r(RRlargo(i))+vent2;
        trozo2=Y(posmaxcorr-vent1:posmaxcorr+vent2);
        auxcorr3=corrcoef(trozo2,promedio);
        corr3=auxcorr3(2,1);
        if corr3>umbralcorr2
            masQRS=[masQRS posmaxcorr];
        end
    end
    if length(masQRS)==0
        terminado=1;
    else
        QRS_r=sort([QRS_r masQRS]);
        RRlargo=find(diff(QRS_r)>(mean(diff(QRS_r))+3*std(diff(QRS_r))));    
        masQRS=[];
    end
end
end