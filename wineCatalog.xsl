<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:key name="regionLookup" match="region" use="@regionId"/>
    <xsl:key name="wineryLookup" match="winery" use="@wineryId"/>

    <xsl:template match="/">
        <html>
            <head>
                <title>Каталог на Български Вина</title>
                <style>
                    body { font-family: 'Segoe UI', sans-serif; background: #f9f9f9; padding: 20px; color: #333; }
                    h1 { text-align: center; color: #722f37; border-bottom: 3px solid #722f37; padding-bottom: 15px; }
                    
                    /* --- CONTROLS --- */
                    .control-panel { 
                        background: white; padding: 15px; margin-bottom: 20px; border-radius: 8px; 
                        box-shadow: 0 2px 5px rgba(0,0,0,0.1); display: flex; flex-wrap: wrap; gap: 15px; justify-content: space-between; align-items: center;
                    }
                    .btn-group button { 
                        padding: 8px 12px; margin-right: 5px; cursor: pointer; border: 1px solid #722f37; 
                        background: white; color: #722f37; border-radius: 4px; font-weight: bold;
                    }
                    .btn-group button:hover { background: #722f37; color: white; }
                    
                    .filters { display: flex; gap: 10px; align-items: center; }
                    .filters select { padding: 6px; border: 1px solid #ccc; border-radius: 4px; }
                    
                    /* --- GRID --- */
                    .catalog-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 20px; }
                    
                    /* --- CARDS --- */
                    .wine-card { 
                        background: white; border-radius: 8px; overflow: hidden; 
                        box-shadow: 0 2px 5px rgba(0,0,0,0.1); cursor: pointer; transition: transform 0.2s;
                        display: flex; flex-direction: column; text-align: center; padding-bottom: 10px;
                    }
                    .wine-card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
                    .card-image { width: 100%; height: 180px; object-fit: contain; background: #f0f0f0; padding: 10px; box-sizing: border-box; }
                    .card-name { padding: 10px; font-weight: bold; color: #2c3e50; min-height: 40px; display: flex; align-items: center; justify-content: center; }
                    .card-price { margin-top: auto; color: #722f37; font-weight: bold; font-size: 1.1em; }
                    
                    /* --- SECTIONS --- */
                    .view-section { display: none; }
                    #view-all { display: block; } /* Default visible */
                    h2.group-title { width: 100%; color: #722f37; border-left: 5px solid #722f37; padding-left: 10px; margin-top: 30px; }

                    /* --- DETAILS PAGE --- */
                    .wine-page { display: none; background: white; max-width: 900px; margin: 0 auto; padding: 30px; border-radius: 8px; box-shadow: 0 0 20px rgba(0,0,0,0.2); }
                    .back-btn { background: #722f37; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin-bottom: 20px; }
                    .page-content { display: flex; gap: 30px; flex-wrap: wrap; }
                    .page-image img { max-width: 300px; width: 100%; border-radius: 8px; }
                    .page-info { flex: 1; }
                    .info-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
                    .info-table td { padding: 8px 0; border-bottom: 1px solid #eee; }
                    .label { font-weight: bold; width: 120px; }
                    
                    /* --- REVIEWS --- */
                    .reviews-section { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
                    .review-container { margin-top: 15px; padding: 10px; background: #fff9c4; border-left: 4px solid #ff9800; display: none; }
                    .review-item { padding-bottom: 10px; margin-bottom: 10px; border-bottom: 1px solid #ddd; }
                    .review-stars { float: right; color: #ff9800; }
                </style>

                <script type="text/javascript">
                <![CDATA[
                    // 1. SWITCH VIEWS
                    function switchView(viewId) {
                        // Hide all sections and pages
                        var sections = document.querySelectorAll('.view-section');
                        for(var i=0; i<sections.length; i++) sections[i].style.display = 'none';
                        
                        var pages = document.querySelectorAll('.wine-page');
                        for(var i=0; i<pages.length; i++) pages[i].style.display = 'none';

                        // Show Control Panel
                        document.getElementById('control-panel').style.display = 'flex';

                        // Show selected view
                        document.getElementById(viewId).style.display = 'block';

                        // Only show Filters/Sort on the "All Wines" view
                        var filters = document.getElementById('filter-controls');
                        if(viewId === 'view-all') {
                            filters.style.visibility = 'visible';
                        } else {
                            filters.style.visibility = 'hidden';
                        }
                    }

                    // 2. OPEN DETAIL PAGE
                    function openWinePage(id) {
                        document.getElementById('control-panel').style.display = 'none';
                        var sections = document.querySelectorAll('.view-section');
                        for(var i=0; i<sections.length; i++) sections[i].style.display = 'none';
                        
                        document.getElementById('page-' + id).style.display = 'block';
                        window.scrollTo(0,0);
                    }

                    function backToCatalog(id) {
                        document.getElementById('page-' + id).style.display = 'none';
                        document.getElementById('control-panel').style.display = 'flex';
                        document.getElementById('view-all').style.display = 'block';
                        document.getElementById('filter-controls').style.visibility = 'visible';
                    }

                    // 3. SORTING
                    function sortByPrice(order) {
                        if(!order) return;
                        var grid = document.getElementById('grid-all');
                        var cards = Array.from(grid.getElementsByClassName('wine-card'));

                        cards.sort(function(a, b) {
                            var p1 = parseFloat(a.getAttribute('data-price'));
                            var p2 = parseFloat(b.getAttribute('data-price'));
                            return order === 'asc' ? p1 - p2 : p2 - p1;
                        });

                        // Re-append to DOM
                        for(var i=0; i<cards.length; i++) {
                            grid.appendChild(cards[i]);
                        }
                    }

                    // 4. FILTERING
                    function applyFilters() {
                        var typeVal = document.getElementById('filterType').value;
                        var vintageVal = document.getElementById('filterVintage').value;
                        
                        var grid = document.getElementById('grid-all');
                        var cards = grid.getElementsByClassName('wine-card');

                        for(var i=0; i<cards.length; i++) {
                            var card = cards[i];
                            var cType = card.getAttribute('data-type');
                            var cVintage = card.getAttribute('data-vintage');

                            // Check matches
                            var matchType = (typeVal === "" || cType === typeVal);
                            var matchVintage = (vintageVal === "" || cVintage === vintageVal);

                            if(matchType && matchVintage) {
                                card.style.display = 'flex';
                            } else {
                                card.style.display = 'none';
                            }
                        }
                    }

                    // 5. FETCH REVIEWS
                    async function loadReviews(btn, wineId) {
                        var container = btn.nextElementSibling;
                        if(container.getAttribute('data-loaded') === 'true') {
                            container.style.display = (container.style.display === 'block') ? 'none' : 'block';
                            btn.innerText = (container.style.display === 'block') ? 'Скрий мнения' : 'Виж мнения';
                            return;
                        }

                        btn.innerText = 'Зареждане...';
                        try {
                            const response = await fetch('reviews.xml');
                            if(!response.ok) throw new Error("Connection failed");
                            const text = await response.text();
                            const parser = new DOMParser();
                            const doc = parser.parseFromString(text, "text/xml");
                            
                            let html = '';
                            let found = false;
                            let reviews = doc.querySelectorAll('review');

                            reviews.forEach(function(r) {
                                if(r.getAttribute('wineId') === wineId) {
                                    found = true;
                                    let rating = r.getAttribute('rating');
                                    let stars = '';
                                    for(let k=0; k<rating; k++) stars += '★';
                                    for(let k=rating; k<5; k++) stars += '☆';
                                    
                                    let user = r.querySelector('user').textContent;
                                    let comment = r.querySelector('comment').textContent;
                                    
                                    html += '<div class="review-item"><span style="font-weight:bold">' + user + '</span>' +
                                            '<span class="review-stars">' + stars + '</span><br/>' +
                                            '<i>"' + comment + '"</i></div>';
                                }
                            });
                            
                            container.innerHTML = found ? html : '<i>Няма мнения.</i>';
                            container.style.display = 'block';
                            container.setAttribute('data-loaded', 'true');
                            btn.innerText = 'Скрий мнения';
                        } catch(e) {
                            console.error(e);
                            btn.innerText = 'Грешка при зареждане';
                        }
                    }
                ]]>
                </script>
            </head>
            <body>
                <h1>Каталог на Български Вина</h1>

                <div id="control-panel" class="control-panel">
                    <div class="btn-group">
                        <button onclick="switchView('view-all')">Всички</button>
                        <button onclick="switchView('view-regions')">По Региони</button>
                        <button onclick="switchView('view-wineries')">По Изби</button>
                    </div>

                    <div id="filter-controls" class="filters">
                        <label>Цена:</label>
                        <select onchange="sortByPrice(this.value)">
                            <option value="">—</option>
                            <option value="asc">Възходящо</option>
                            <option value="desc">Низходящо</option>
                        </select>

                        <label>Тип:</label>
                        <select id="filterType" onchange="applyFilters()">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(type=preceding::type)]">
                                <option value="{type}"><xsl:value-of select="type"/></option>
                            </xsl:for-each>
                        </select>

                        <label>Реколта:</label>
                        <select id="filterVintage" onchange="applyFilters()">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(vintage=preceding::vintage)]">
                                <xsl:sort select="vintage" data-type="number"/>
                                <option value="{vintage}"><xsl:value-of select="vintage"/></option>
                            </xsl:for-each>
                        </select>
                    </div>
                </div>

                <div id="view-all" class="view-section">
                    <div id="grid-all" class="catalog-grid">
                        <xsl:call-template name="renderCards">
                            <xsl:with-param name="items" select="wineCatalog/wines/wine"/>
                        </xsl:call-template>
                    </div>
                </div>

                <div id="view-regions" class="view-section">
                    <xsl:for-each select="wineCatalog/regions/region">
                        <h2 class="group-title"><xsl:value-of select="name"/></h2>
                        <div class="catalog-grid">
                            <xsl:variable name="rid" select="@regionId"/>
                            <xsl:call-template name="renderCards">
                                <xsl:with-param name="items" select="/wineCatalog/wines/wine[@regionIdRef=$rid]"/>
                            </xsl:call-template>
                        </div>
                    </xsl:for-each>
                </div>

                <div id="view-wineries" class="view-section">
                    <xsl:for-each select="wineCatalog/wineries/winery">
                        <h2 class="group-title"><xsl:value-of select="name"/></h2>
                        <div class="catalog-grid">
                            <xsl:variable name="wid" select="@wineryId"/>
                            <xsl:call-template name="renderCards">
                                <xsl:with-param name="items" select="/wineCatalog/wines/wine[@wineryIdRef=$wid]"/>
                            </xsl:call-template>
                        </div>
                    </xsl:for-each>
                </div>

                <xsl:for-each select="wineCatalog/wines/wine">
                    <div id="page-{@wineId}" class="wine-page">
                        <button class="back-btn" onclick="backToCatalog('{@wineId}')">← Обратно</button>
                        <div class="page-content">
                            <div class="page-image">
                                <img src="{unparsed-entity-uri(image/@source)}" />
                            </div>
                            <div class="page-info">
                                <h2 style="color:#722f37; margin-top:0;"><xsl:value-of select="name"/></h2>
                                <table class="info-table">
                                    <tr><td class="label">Цена:</td><td style="color:#722f37; font-weight:bold;"><xsl:value-of select="price"/> <xsl:value-of select="price/@currency"/></td></tr>
                                    <tr><td class="label">Тип:</td><td><xsl:value-of select="type"/></td></tr>
                                    <tr><td class="label">Реколта:</td><td><xsl:value-of select="vintage"/></td></tr>
                                    <tr><td class="label">Изба:</td><td><xsl:value-of select="key('wineryLookup', @wineryIdRef)/name"/></td></tr>
                                    <tr><td class="label">Регион:</td><td><xsl:value-of select="key('regionLookup', @regionIdRef)/name"/></td></tr>
                                    <xsl:if test="rating">
                                        <tr><td class="label">Рейтинг:</td><td><xsl:value-of select="rating"/></td></tr>
                                    </xsl:if>
                                </table>
                                <div style="margin-top:20px; font-style:italic; border-left:4px solid #ff9800; padding:10px; background:#fdfdfd;">
                                    <xsl:value-of select="sommelierDescription"/>
                                </div>
                                <div class="reviews-section">
                                    <h3>Мнения</h3>
                                    <button onclick="loadReviews(this, '{@wineId}')" style="cursor:pointer; padding:6px 12px;">Виж мнения</button>
                                    <div class="review-container"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </xsl:for-each>
            </body>
        </html>
    </xsl:template>

    <xsl:template name="renderCards">
        <xsl:param name="items"/>
        <xsl:for-each select="$items">
            <div class="wine-card" 
                 onclick="openWinePage('{@wineId}')" 
                 data-price="{price}" 
                 data-type="{type}" 
                 data-vintage="{vintage}">
                <img class="card-image" src="{unparsed-entity-uri(image/@source)}" alt="{name}"/>
                <div class="card-name"><xsl:value-of select="name"/></div>
                <div class="card-price">
                    <xsl:value-of select="price"/> <xsl:value-of select="price/@currency"/>
                </div>
            </div>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>