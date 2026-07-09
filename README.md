# Gestión de inversión MOP

Este repositorio contiene un script SQL para cargar datos de inversión del MOP en una base de datos MySQL y generar vistas y tablas de análisis.

## Archivos incluidos
- sql_trabajo.sql: script principal con la carga de datos, creación de tablas y vistas.
- detalleinversionhistoricamop2011-2018.xlsx: archivo fuente con los datos.
- Tarea3Gestion.pbix: archivo de Power BI relacionado al análisis.

## Requisitos
- MySQL instalado y en ejecución.
- Una base de datos creada para cargar los datos.
- El archivo CSV/Excel debe estar disponible en la ruta indicada en el script.

## Uso
1. Abrir el archivo sql_trabajo.sql.
2. Ajustar la ruta del archivo en la instrucción LOAD DATA LOCAL INFILE si es necesario.
3. Ejecutar el script en MySQL.
4. Revisar los resultados con las consultas finales del archivo.

