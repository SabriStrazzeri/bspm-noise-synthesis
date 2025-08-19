function [ptosanclaje]=ECGDELINEATION_tiralineas(Y,iter,umbral)

% Modificacion de la funcion tiralineas por Maria
% iter indica cuantas iteraciones más podemos hacer
% Ahora se ejecutara de forma recursiva de manera que vamos dividiendo cada
% segmento hasta que la distancia maxima sea inferior al umbral

ns=length(Y);

ptosanclaje=[1 ns];
distanciamaxima=Inf;
numiter=0;
while distanciamaxima>umbral & numiter<iter & ns>10
        x1=ptosanclaje(1);
        x2=ptosanclaje(end);
        y1=Y(x1);
        y2=Y(x2);
        m=(y2-y1)/(x2-x1);
        xrecta=1:(x2-x1)+1;
        recta(x1:x2)=y1+m.*xrecta;
        distancia=abs(recta-Y);
        [distanciamaxima,auxposmaxdist]=max(distancia);
        if distanciamaxima>umbral
                posmaxdist=auxposmaxdist;
                ptosanclaje=sort(unique([ptosanclaje posmaxdist]));
                [ptosanclaje1]=ECGDELINEATION_tiralineas(Y(ptosanclaje(1):ptosanclaje(2)),iter-1,umbral);
                [ptosanclaje2]=ECGDELINEATION_tiralineas(Y(ptosanclaje(2):end),iter-1,umbral);
                ptosanclaje=sort(unique([ptosanclaje1 ptosanclaje2+ptosanclaje(2)-1]));
                distanciamaxima=umbral-1;
        end
end
end