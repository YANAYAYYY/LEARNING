/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM Nashvillehousedata.dbo.Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------

--Standardize Date Format

--SELECT SaleDate,CONVERT(Date,SaleDate) as ConvertDateSaleDate
--FROM Nashvillehousedata.dbo.Nashvillehousing    --查看

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD SaleDateConverted Date;

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDate, SaleDateConverted
FROM Nashvillehousedata.dbo.Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------

--Populate Property Address date

SELECT *
FROM Nashvillehousedata.dbo.Nashvillehousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

--ParcelID相同但UniqueID不同，并且其中一行（a）的PropertyAddress为空的情况下，选取这两行数据。
--同时，它期望通过这种方式找到可以用于填充空缺PropertyAddress的有效值，即选取那些与之具有相同ParcelID但PropertyAddress非空的记录。
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
--左边两列是表中PropertyAddress为空的内容，右边两列是表中具有相同ParcelID但PropertyAddress非空的内容。ISNULL(a.PropertyAddress,b.PropertyAddress)
--ISNULL(a.PropertyAddress,b.PropertyAddress)是指当a.PropertyAddress为空时，用b.PropertyAddress的内容代替
FROM Nashvillehousedata.dbo.Nashvillehousing a
JOIN Nashvillehousedata.dbo.Nashvillehousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--将所有PropertyAddress空的值替换成与它ParcelID一样的内容
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Nashvillehousedata.dbo.Nashvillehousing a
JOIN Nashvillehousedata.dbo.Nashvillehousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

----------------------------------------------------------------------------------------------------------------------------

--Breaking out Address into Individual Columns(Address,city,State)

SELECT PropertyAddress
FROM Nashvillehousedata.dbo.Nashvillehousing

SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,   --提取地址逗号前的内容成为一个新列
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City  --提取地址逗号后的内容成为city
FROM Nashvillehousedata.dbo.Nashvillehousing

--SUBSTRING的参数：第一个参数是原始字符串;第二个参数是起始位置，1代表从第一个字符开始;第三个参数是要提取的字符数。
--CHARINDEX(',', PropertyAddress)：这个函数会在 PropertyAddress 字符串中查找第一个逗号的位置，返回其索引（从1开始计数）。

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD PropertySplitAddress Nvarchar(225);
--Nvarchar：N能够支持全球各种语言和字符集，不带N可能不能识别如中、日、韩文。varchar是指Variable Character

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD PropertySplitCity Nvarchar(225);

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

--换一种方式去提取OwnerAddress

SELECT OwnerAddress
FROM Nashvillehousedata.dbo.Nashvillehousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),   --PARSENAME()函数用于根据句点（'.'）分隔符来拆分字符串
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashvillehousedata.dbo.Nashvillehousing

--这种情况不能一起执行，会报错，需要一条一条执行。
ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD OwnerSplitAddress Nvarchar(225);

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD OwnerSplitcity Nvarchar(225);

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET OwnerSplitcity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD OwnerSplitstate Nvarchar(225);

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET OwnerSplitstate = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

----------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

SELECT SoldAsVacant
FROM Nashvillehousedata.dbo.Nashvillehousing

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)  --Distinct:选择不重复的SoldAsVacant字段值; Count计算了SoldAsVacant字段的总数量,但是一般生成的行数不同不能放一起，所以需要一个group by
FROM Nashvillehousedata.dbo.Nashvillehousing
GROUP BY SoldAsVacant  --如果想要得到每种不同的SoldAsVacant状态及其对应的数量，应使用GROUP BY语句.
ORDER BY 2

SELECT 
SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
     WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END
FROM Nashvillehousedata.dbo.Nashvillehousing

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
                        WHEN SoldAsVacant = 'N' THEN 'NO'
	                    ELSE SoldAsVacant
	                    END 

----------------------------------------------------------------------------------------------------------------------------

--Remove Duplicate (删重复的行）

WITH RowNumCTE AS   --创建公共表表达式（Common Table Expression, CTE）
(
SELECT *,
      ROW_NUMBER() OVER( 
	      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference   
		  --PARTITON BY是分区依据，根据ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference分区，每一行记1，如果有两个上述相同的记2。
		  ORDER BY UniqueID) AS row_num
FROM Nashvillehousedata.dbo.Nashvillehousing
--WHERE row_num > 1    --此处没办法直接引用row_num,所以才利用CTE来创建临时表RowNumCTE，再引用row_num
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1    --row_num大于1说明，至少有两行中，ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference是相同的，说明其重复了，可以删掉

--检查是否删成功了
WITH RowNumCTE AS   --创建公共表表达式（Common Table Expression, CTE）
(
SELECT *,
      ROW_NUMBER() OVER( 
	      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference   
		  --PARTITON BY是分区依据，根据ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference分区，每一行记1，如果有两个上述相同的记2。
		  ORDER BY UniqueID) AS row_num
FROM Nashvillehousedata.dbo.Nashvillehousing
--WHERE row_num > 1    --此处没办法直接引用row_num,所以才利用CTE来创建临时表RowNumCTE，再引用row_num
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1

----------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns （删列）

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing
DROP COLUMN SaleDate