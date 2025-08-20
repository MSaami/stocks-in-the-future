# frozen_string_literal: true

require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio).validate!
  end

  test "#cash_balance" do
    portfolio = create(:portfolio)
    user = portfolio.user

    # should increase cash_balance
    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 1000)

    stock = create(:stock, price_cents: 100)

    # This simulates previous completed purchases
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 100)

    # pending debit for stock purchase, should decrease cash_balance
    create(:order, :pending, :buy, stock:, shares: 2, user:)

    # pending credit for stock sale, should NOT affect cash_balance
    create(:order, :pending, :sell, stock:, shares: 3, user:)

    # canceled debit for stock purchase, should NOT affect cash_balance
    create(:order, :canceled, :buy, stock:, shares: 1, user:)

    # canceled credit for stock sale, should NOT affect cash_balance
    create(:order, :canceled, :sell, stock:, shares: 4, user:)

    # successful completed stock purchase, should decrease cash_balance
    create(:order, :completed, :buy, stock:, shares: 5, user:)

    # successful completed stock sale, should increase cash_balance
    create(:order, :completed, :sell, stock:, shares: 6, user:)

    # withdrawal from the account, should decrease cash_balance
    create(:portfolio_transaction, :withdrawal, portfolio:, amount_cents: 200)

    result = portfolio.cash_balance
    assert_equal 7.0, result
  end

  test "#shares_owned with single purchase" do
    portfolio = create(:portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 15, purchase_price: 200.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 15, result
  end

  test "#shares_owned with multiple purchases aggregates correctly" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 5, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 18, result # 10 + 5 + 3
  end

  test "#shares_owned with buy and sell orders" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 20, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: -7, purchase_price: 250.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock, shares: 3, purchase_price: 300.0)

    result = portfolio.shares_owned(stock.id)
    assert_equal 16, result # 20 - 7 + 3
  end

  test "#shares_owned returns 0 when no shares owned" do
    portfolio = create(:portfolio)
    stock = create(:stock)

    result = portfolio.shares_owned(stock.id)
    assert_equal 0, result
  end

  test "#shares_owned with different stocks" do
    portfolio = create(:portfolio)
    stock1 = create(:stock)
    stock2 = create(:stock)

    create(:portfolio_stock, portfolio: portfolio, stock: stock1, shares: 10, purchase_price: 200.0)
    create(:portfolio_stock, portfolio: portfolio, stock: stock2, shares: 5, purchase_price: 300.0)

    assert_equal 10, portfolio.shares_owned(stock1.id)
    assert_equal 5, portfolio.shares_owned(stock2.id)
  end
end
