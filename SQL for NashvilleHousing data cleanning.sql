/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM Nashvillehousedata.dbo.Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------

--Standardize Date Format

--SELECT SaleDate,CONVERT(Date,SaleDate) as ConvertDateSaleDate
--FROM Nashvillehousedata.dbo.Nashvillehousing    --�鿴

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

--ParcelID��ͬ��UniqueID��ͬ����������һ�У�a����PropertyAddressΪ�յ�����£�ѡȡ���������ݡ�
--ͬʱ��������ͨ�����ַ�ʽ�ҵ�������������ȱPropertyAddress����Чֵ����ѡȡ��Щ��֮������ͬParcelID��PropertyAddress�ǿյļ�¼��
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
--��������Ǳ���PropertyAddressΪ�յ����ݣ��ұ������Ǳ��о�����ͬParcelID��PropertyAddress�ǿյ����ݡ�ISNULL(a.PropertyAddress,b.PropertyAddress)
--ISNULL(a.PropertyAddress,b.PropertyAddress)��ָ��a.PropertyAddressΪ��ʱ����b.PropertyAddress�����ݴ���
FROM Nashvillehousedata.dbo.Nashvillehousing a
JOIN Nashvillehousedata.dbo.Nashvillehousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--������PropertyAddress�յ�ֵ�滻������ParcelIDһ��������
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
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,   --��ȡ��ַ����ǰ�����ݳ�Ϊһ������
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City  --��ȡ��ַ���ź�����ݳ�Ϊcity
FROM Nashvillehousedata.dbo.Nashvillehousing

--SUBSTRING�Ĳ�������һ��������ԭʼ�ַ���;�ڶ�����������ʼλ�ã�1����ӵ�һ���ַ���ʼ;������������Ҫ��ȡ���ַ�����
--CHARINDEX(',', PropertyAddress)������������� PropertyAddress �ַ����в��ҵ�һ�����ŵ�λ�ã���������������1��ʼ��������

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD PropertySplitAddress Nvarchar(225);
--Nvarchar��N�ܹ�֧��ȫ��������Ժ��ַ���������N���ܲ���ʶ�����С��ա����ġ�varchar��ָVariable Character

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing ADD PropertySplitCity Nvarchar(225);

UPDATE Nashvillehousedata.dbo.Nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

--��һ�ַ�ʽȥ��ȡOwnerAddress

SELECT OwnerAddress
FROM Nashvillehousedata.dbo.Nashvillehousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),   --PARSENAME()�������ڸ��ݾ�㣨'.'���ָ���������ַ���
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashvillehousedata.dbo.Nashvillehousing

--�����������һ��ִ�У��ᱨ����Ҫһ��һ��ִ�С�
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

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)  --Distinct:ѡ���ظ���SoldAsVacant�ֶ�ֵ; Count������SoldAsVacant�ֶε�������,����һ�����ɵ�������ͬ���ܷ�һ��������Ҫһ��group by
FROM Nashvillehousedata.dbo.Nashvillehousing
GROUP BY SoldAsVacant  --�����Ҫ�õ�ÿ�ֲ�ͬ��SoldAsVacant״̬�����Ӧ��������Ӧʹ��GROUP BY���.
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

--Remove Duplicate (ɾ�ظ����У�

WITH RowNumCTE AS   --������������ʽ��Common Table Expression, CTE��
(
SELECT *,
      ROW_NUMBER() OVER( 
	      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference   
		  --PARTITON BY�Ƿ������ݣ�����ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference������ÿһ�м�1�����������������ͬ�ļ�2��
		  ORDER BY UniqueID) AS row_num
FROM Nashvillehousedata.dbo.Nashvillehousing
--WHERE row_num > 1    --�˴�û�취ֱ������row_num,���Բ�����CTE��������ʱ��RowNumCTE��������row_num
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1    --row_num����1˵���������������У�ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference����ͬ�ģ�˵�����ظ��ˣ�����ɾ��

--����Ƿ�ɾ�ɹ���
WITH RowNumCTE AS   --������������ʽ��Common Table Expression, CTE��
(
SELECT *,
      ROW_NUMBER() OVER( 
	      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference   
		  --PARTITON BY�Ƿ������ݣ�����ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference������ÿһ�м�1�����������������ͬ�ļ�2��
		  ORDER BY UniqueID) AS row_num
FROM Nashvillehousedata.dbo.Nashvillehousing
--WHERE row_num > 1    --�˴�û�취ֱ������row_num,���Բ�����CTE��������ʱ��RowNumCTE��������row_num
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1

----------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns ��ɾ�У�

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Nashvillehousedata.dbo.Nashvillehousing
DROP COLUMN SaleDate