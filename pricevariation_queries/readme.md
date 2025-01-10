1. Provide the API collection and documentation related to supplier integration for dynamic pricing? - Can be get from third party

2. Should this implementation be categorized under new library integration or existing systems? -- I think its purely depends upon us and no need to ask this query from client as we know the system well that where we need to provide this feature

3. Will the third party provide both the cost price and list price?
    a) We can make system on basis of variable that if third party providing pricing then we use that otherwise we can continue with the our pricing structure
    b) if third party providing the procing then it will be the pricing of supplier side where we have the cost and sale price but after that on basis of the currency conversion we will record it in the financials 
    c) if third party provide us the pricing then we can store there basic sale and coct price in a seperate column for easily idenfication and query purpose
    d) as per recent case and financial table updated by us for galaxy connecty we already have these pricing in gray log but it takes 1 week to retrive that data so it should be easily available

4. If the answer to the previous question is no, how will pricing calculations be handled?
    a) if third party not pricing the pricing then we will calculate pricing according to our system so not able to understand this query

5. Will there be a concept of markup? If so, how will it function?
    a) if client requested for price variation and there purpose solve with this then we not need to ask for markup from them

6. Will there be a concept of partner commission? If so, how will it be implemented?
    a) partner commission only applicable only in case of group booking so is it needed there

7. Should the markup be specific to accounts, distributors, resellers, or products?
    a) this point not needed if price variation solve our purpose

8. Should the partner commission be specific to accounts, distributors, resellers, or products?
    b) if not related to group booking then not needed this

9. Is it necessary to display the pricing on a calendar?
    a) yes we already handling it in catalog so we can manage this but after synch it on redis but if there are grequesnt change in there pricing then we need to think about it that how we will handle.

10. Do we need to cache the pricing information from third parties?
    -- that completely depends upon our system in this case client can't confirm this 

11. Will commissions for product variations be applicable?
    -- its according to catalog feature and this client can't confirm but we need to inform them

12. Will discounts for product variations be applicable? If so, how will fixed discounts be managed?
    -- should be work as per existing system

13. How many OTAs (Online Travel Agencies) will sell these products? Will external OTAs also be involved in selling these products?
    -- depends on client information

14. Do supplier have runtime pricing or Variable pricing? - client confirmation needed
15. How frequently it change its prices? client confirmation needed in it
16. How prio need to check if prices change at supplier end? I think its depends internally upon us
17. Prices will be manage by Catalog or run time pricing? -- same query as above