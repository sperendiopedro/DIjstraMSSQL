CREATE PROCEDURE DIJKSTRA 
    @StartPoint INT, 
    @EndPoint INT
AS 
BEGIN 
    DECLARE @Infinity INT = 1000000; 

    CREATE TABLE #DISTANCIAS_MINIMAS
    (
        ID_PONTO INT, 
        DISTANCIA INT, 
        ANTERIOR INT
    ); 

    INSERT INTO #DISTANCIAS_MINIMAS (ID_PONTO, DISTANCIA, ANTERIOR)
    SELECT DISTINCT ID_Origem, CASE WHEN ID_Origem = @StartPoint THEN 0 ELSE @Infinity END, NULL
    FROM ARESTAS
    UNION
    SELECT DISTINCT ID_Destino, CASE WHEN ID_Destino = @StartPoint THEN 0 ELSE @Infinity END, NULL
    FROM ARESTAS;

    CREATE TABLE #Visitados (
        ID_Ponto INT PRIMARY KEY
    );

    WHILE EXISTS (SELECT 1 FROM #DISTANCIAS_MINIMAS dm LEFT JOIN #Visitados v ON dm.ID_PONTO = v.ID_Ponto WHERE v.ID_Ponto IS NULL)
    BEGIN
        -- Selecionar ponto não visitado com a menor distancia
        DECLARE @MinDistancia INT, @MinPonto INT;
        SELECT TOP 1 @MinPonto = dm.ID_Ponto, @MinDistancia = dm.Distancia
        FROM #DISTANCIAS_MINIMAS dm
        LEFT JOIN #Visitados v ON dm.ID_PONTO = v.ID_Ponto
        WHERE v.ID_Ponto IS NULL
        ORDER BY dm.Distancia;

        -- Marcar o ponto como visitado
        INSERT INTO #Visitados (ID_Ponto) VALUES (@MinPonto);

        -- Atualizar a distancia dos vizinhos
        UPDATE dm
        SET dm.Distancia = @MinDistancia + a.Distancia, dm.Anterior = @MinPonto
        FROM #DISTANCIAS_MINIMAS dm
        JOIN ARESTAS a ON dm.ID_Ponto = a.ID_Destino
        WHERE a.ID_Origem = @MinPonto AND dm.Distancia > @MinDistancia + a.Distancia AND dm.ID_Ponto NOT IN (SELECT ID_Ponto FROM #Visitados);

        -- Para se o ponto for visitado
        IF EXISTS (SELECT 1 FROM #Visitados WHERE ID_Ponto = @EndPoint)
            BREAK;
    END

    -- Tabela temp para o caminho 
    CREATE TABLE #Caminho (
        ID_Ponto INT,
        Distancia INT
    );

    DECLARE @PontoAtual INT = @EndPoint;
    DECLARE @DistanciaAtual INT;
    WHILE @PontoAtual IS NOT NULL
    BEGIN
        SELECT @DistanciaAtual = Distancia FROM #DISTANCIAS_MINIMAS WHERE ID_Ponto = @PontoAtual;
        INSERT INTO #Caminho (ID_Ponto, Distancia)
        VALUES (@PontoAtual, @DistanciaAtual);

        SELECT @PontoAtual = Anterior FROM #DISTANCIAS_MINIMAS WHERE ID_Ponto = @PontoAtual;
    END

    -- Retorna o caminho e distancia
    SELECT ID_Ponto, Distancia
    FROM #Caminho
    ORDER BY Distancia;

    DROP TABLE #DISTANCIAS_MINIMAS;
    DROP TABLE #Visitados;
    DROP TABLE #Caminho;
END;