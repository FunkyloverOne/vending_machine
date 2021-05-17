# frozen_string_literal: true

require 'vending_machine'

RSpec.describe VendingMachine do
  let(:juice) { Product.new('Orange Juice', 7.50) }
  let(:soda) { Product.new('Dr Pepper', 4.25) }
  let(:granola) { Product.new('Granola Bar', 3.50) }
  let(:snickers) { Product.new('Snickers Bar', 3.75) }
  let(:lemonade) { Product.new('Lemonade', 5.00) }
  let(:lays) { Product.new('Lays', 4.00) }

  let(:product_stock) do
    ProductStock.new(
      [
        StockedProduct.new(juice, 5),
        StockedProduct.new(soda, 1),
        StockedProduct.new(granola, 5),
        StockedProduct.new(snickers, 5),
        StockedProduct.new(lemonade, 5),
        StockedProduct.new(lays, 1)
      ]
    )
  end

  let(:coin_stock) do
    CoinStock.new(
      0.25 => 10,
      0.50 => 10,
      1.00 => 10,
      2.00 => 10,
      5.00 => 10
    )
  end

  subject(:vending_machine) do
    described_class.new(product_stock: product_stock, coin_stock: coin_stock)
  end

  describe '#select_product' do
    it 'returns selected product when it is fully paid' do
      vending_machine.insert_coins(5.00, 2.00, 0.50)

      expect(vending_machine.select_product(0)).to eq(product: juice)
    end

    it 'reduces selected product from stock' do
      vending_machine.insert_coins(5.00, 2.00, 0.50)

      expect { vending_machine.select_product(0) }.to(
        change { vending_machine.units_in_stock(0) }.from(5).to(4)
      )
    end

    it 'returns change if too much money is provided' do
      vending_machine.insert_coins(5.00)

      expect(vending_machine.select_product(1))
        .to eq(product: soda, change: { 0.50 => 1, 0.25 => 1 })
    end

    it 'updates coin stock accordingly' do
      vending_machine.insert_coins(5.00)

      expect { vending_machine.select_product(1) }.to(
        change { vending_machine.coins_in_stock }.from(
          0.25 => 10,
          0.50 => 10,
          1.00 => 10,
          2.00 => 10,
          5.00 => 10
        ).to(
          0.25 => 9,
          0.50 => 9,
          1.00 => 10,
          2.00 => 10,
          5.00 => 11
        )
      )
    end

    shared_examples 'not touching stocks' do
      it 'does not change product stock' do
        expect { vending_machine.select_product(product_id) }
          .to_not(change { vending_machine.units_in_stock(product_id) })
      end

      it 'does not change coin stock' do
        expect { vending_machine.select_product(product_id) }
          .to_not(change { vending_machine.coins_in_stock })
      end
    end

    context 'when not enough money inserted' do
      before { vending_machine.insert_coins(5.00, 2.00) }

      let(:product_id) { 0 }
      it_behaves_like 'not touching stocks'

      it 'asks for more money' do
        expect(vending_machine.select_product(product_id)).to eq(
          error: 'Not enough money. ' \
                 'Price: 7.50; Inserted Amount: 7.00; Need 0.50 more.'
        )
      end
    end

    context 'when not enough coins for a change' do
      let(:coin_stock) do
        CoinStock.new(
          0.25 => 0,
          0.50 => 10,
          1.00 => 10,
          2.00 => 10,
          5.00 => 10
        )
      end

      before { vending_machine.insert_coins(5.00) }

      let(:product_id) { 1 }
      it_behaves_like 'not touching stocks'

      it 'returns an error message' do
        expect(vending_machine.select_product(product_id)).to eq(
          error: 'Cannot return a change, not enough required coins.'
        )
      end
    end

    context 'when the selected product is out of stock' do
      let(:product_stock) do
        ProductStock.new([StockedProduct.new(juice, 0)])
      end

      before { vending_machine.insert_coins(5.00, 2.00, 0.50) }

      let(:product_id) { 0 }
      it_behaves_like 'not touching stocks'

      it 'returns an error message' do
        expect(vending_machine.select_product(product_id)).to eq(
          error: 'The selected product is out of stock.'
        )
      end
    end
  end
end
