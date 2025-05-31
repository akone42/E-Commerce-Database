# 🛒 Fetsy E-Commerce Database Normalization Project

This project focuses on transforming a denormalized dataset of 400,000 ecommerce order records into a fully normalized MySQL database in **Third Normal Form (3NF)**. The dataset simulates order data for an online retail platform called **Fetsy**.

## 📚 Objective

Design and implement a relational database schema that:
- Eliminates redundancy
- Enforces data integrity
- Supports scalable querying and analysis

---

## 🔧 Key Features

### Data Normalization
- Converted the original flat file into **3NF** across multiple relational tables
- Identified and enforced **1:1**, **1:many**, and **many:many** relationships
- Preserved original column names to maintain dataset compatibility

### Schema Design
- Defined appropriate **data types**, **primary/foreign keys**, and **constraints**
- Created ERD (Entity Relationship Diagram) and determined cardinalities through exploratory SQL queries

### Indexing & Performance
- Added indexes to optimize performance
- Justified indexing strategy using **`EXPLAIN`** before and after analysis
- Documented cases where indexing wasn’t beneficial and why

### Stored Procedure
- Created a parameterized stored procedure

