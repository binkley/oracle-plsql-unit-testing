#!/bin/bash
${SQLPLUS-sqlplus} sqlplus $1/$2@$3:$4/$5 @install.sql
